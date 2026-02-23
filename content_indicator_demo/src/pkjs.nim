## Phone-side logic for content_indicator_demo in Nim

import nebble/pkjs
import std/jsffi
import gen/app_keys

proc onReady(e: ReadyEvent) {.cdecl.} =
  echo "JS component ready (Nim)!"
  
  # Signal to watch that JS is ready
  let data = newJsObject()
  data[cstring"JSReady"] = 1.toJs()
  Pebble.sendAppMessage(data)

proc onMessage(e: AppMessageEvent) {.cdecl.} =
  echo "Received message"
  
  if e.payload.hasOwnProperty("WatchReady"):
    # If watch signals it's ready, respond with JSReady
    let data = newJsObject()
    data[cstring"JSReady"] = 1.toJs()
    Pebble.sendAppMessage(data)

onReady(onReady)
onAppMessage(onMessage)
