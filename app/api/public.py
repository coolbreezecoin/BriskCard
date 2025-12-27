from fastapi import APIRouter, HTTPException, Path
import httpx

from ..config import MISACARD_API_HEADERS, MISACARD_API_BASE_URL
from ..utils.activation import get_card_transactions

router = APIRouter(prefix="/public", tags=["Public"])


async def _post_to_mercury(endpoint: str, payload: dict):
    timeout = httpx.Timeout(30.0, connect=10.0)
    async with httpx.AsyncClient(timeout=timeout, follow_redirects=True, verify=False) as client:
        response = await client.post(
            f"{MISACARD_API_BASE_URL}{endpoint}",
            headers=MISACARD_API_HEADERS,
            json=payload,
        )
        try:
            data = response.json()
        except Exception:
            raise HTTPException(status_code=502, detail="上游接口返回异常")

        if response.status_code >= 500:
            raise HTTPException(status_code=502, detail=data.get("error") or data.get("msg") or "上游接口错误")

        return response.status_code, data


@router.post("/query-key", summary="公开卡密查询代理")
async def public_query_card(payload: dict):
    if "key" not in payload:
        raise HTTPException(status_code=400, detail="缺少 key 参数")

    status_code, data = await _post_to_mercury("/query", payload)
    if status_code == 200:
        return data
    raise HTTPException(status_code=status_code, detail=data)


@router.post("/redeem-key", summary="公开卡密激活代理")
async def public_redeem_card(payload: dict):
    if "key" not in payload:
        raise HTTPException(status_code=400, detail="缺少 key 参数")

    status_code, data = await _post_to_mercury("/redeem", payload)
    if status_code == 200:
        return data
    raise HTTPException(status_code=status_code, detail=data)


@router.get("/card-info/{card_number}", summary="公开卡号查询代理")
async def public_card_info(card_number: str = Path(..., description="卡号")):
    success, data, error = await get_card_transactions(card_number)
    if success and data is not None:
        return {"result": data}
    raise HTTPException(status_code=400, detail=error or "查询失败")
