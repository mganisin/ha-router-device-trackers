import os
import json
import asyncio
import logging
from robyn import Robyn, Request, status_codes
from aiomqtt import Client, MqttError


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("webhook4mqtt")

MQTT_BROKER = os.environ.get("MQTT_BROKER", "localhost")
MQTT_PORT = int(os.environ.get("MQTT_PORT", 1883))
MQTT_USER = os.environ.get("MQTT_USER", None)
MQTT_PASS = os.environ.get("MQTT_PASS", None)

app = Robyn(__file__)
msg_queue = asyncio.Queue()


async def mqtt_worker():
    while True:
        try:
            async with Client(
                hostname=MQTT_BROKER,
                port=MQTT_PORT,
                username=MQTT_USER,
                password=MQTT_PASS
            ) as client:
                logger.info(f"MQTT worker connected to {MQTT_BROKER}")
                while True:
                    topic, payload, retain = await msg_queue.get()
                    await client.publish(topic, payload, retain=retain)
                    msg_queue.task_done()
        except (MqttError, Exception) as e:
            logger.error(f"MQTT Worker Error: {e}. Retrying in 5s...")
            await asyncio.sleep(5)


@app.post("/publish")
async def publish(request: Request):
    try:
        body = request.body
        if isinstance(body, bytes):
            body = body.decode("utf-8")
        
        data = json.loads(body)
        
        topic = data.get("topic")
        message = data.get("message")
        retain = data.get("retain", False)

        if not topic or message is None:
            logger.warning(f"Incomplete payload: {data}")
            return status_codes.HTTP_422_UNPROCESSABLE_ENTITY

        payload = json.dumps(message) if isinstance(message, (dict, list)) else str(message)
        
        await msg_queue.put((topic, payload, retain))
        
        return {"status": "queued"}
        
    except json.JSONDecodeError:
        logger.error("Failed to decode JSON from request")
        return status_codes.HTTP_400_BAD_REQUEST
    except Exception as e:
        logger.error(f"Internal error: {e}")
        return status_codes.HTTP_500_INTERNAL_SERVER_ERROR


@app.startup_handler
async def startup():
    asyncio.create_task(mqtt_worker())


if __name__ == "__main__":
    app.start(host="0.0.0.0", port=5000)
