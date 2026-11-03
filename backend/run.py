import os
import uvicorn

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    is_prod = os.environ.get("ENVIRONMENT", "development").lower() == "production"
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=not is_prod)
