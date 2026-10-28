# CopraWatch Capture Enclosure Setup and Acceptance

This procedure is for the technician who builds and maintains the controlled capture enclosure. The app and backend cannot physically mount the camera, finish the metal, install lighting, or calibrate the enclosure.

## Materials to prepare

### Already available — do not buy again

- Raspberry Pi board
- MAX6675 thermocouple amplifier and K-type thermocouple
- SHT30-D temperature/humidity sensor

Buy only parts that are missing or not suitable for the enclosure. Measure the enclosure and check the existing camera, wiring, power supplies, and mounting hardware before ordering.

### Button and indicator

- 1× momentary, normally-open (NO), panel-mount push button.
- 1× indicator LED and 1× 220 Ω resistor, if an indicator is required and not already available.
- Stranded hookup wire, suitable connectors (such as JST or screw terminals), heat-shrink tubing, and a small perfboard or terminal block for secure connections.

The backend uses BCM GPIO17 for the button and BCM GPIO18 for the LED. Connect the NO button between GPIO17 (physical header pin 11) and GND (for example, physical pin 6); the software enables the Pi's internal pull-up, so an external 10 kΩ pull-up is normally unnecessary. Connect the LED in series with its 220 Ω resistor between GPIO18 (physical pin 12) and GND, observing LED polarity. Never connect an LED directly to a GPIO pin or exceed the Raspberry Pi GPIO voltage/current limits.

### Enclosure, lighting, and positioning

- Metal-compatible primer and matte, neutral-gray paint for the enclosure interior, if needed.
- Diffused, flicker-free 5000 K lighting with CRI 90+ (for example, one or two LED bars that fit the enclosure).
- A separate DC power supply rated for the selected lights' voltage and current; do not power the lights from Raspberry Pi GPIO pins.
- Diffuser material, cable clips or glands, and mounting hardware to keep lighting and wiring fixed.
- A rigid camera bracket with the correct screws or standoffs for the existing camera module.
- A removable sample tray or placement guide to keep copra in a consistent position and orientation.

Do not buy another camera if the existing one is compatible. If painting, let the coating fully cure before installing electronics or capturing samples. Keep the camera, button, and lighting wiring secured and clear of moving or hot parts.

## Fixed capture conditions

- Rigidly mount the camera so its angle, orientation, and focus cannot shift during normal loading or cleaning. Mark and record the lens-to-sample distance and the sample placement location.
- Place copra in the same marked area and orientation for each capture. Keep the camera's field of view and the sample size consistent.
- Use a matte, neutral, non-reflective interior (for example, neutral gray). Avoid glossy paint and bright colors that can introduce glare or color casts.
- Use diffuse, even, stable lighting. Avoid direct point sources, flicker, strong shadows, and changing daylight. Shield the capture area from ambient light and close the enclosure consistently before capture.
- Keep lighting and camera settings fixed once accepted. Record any replacement, adjustment, repainting, or movement before collecting more dataset images; those changes can shift model results and may require a new calibration/validation set.

## Repeat-capture acceptance checklist

With the enclosure assembled and normal operating lights on:

1. Capture at least five images of the same representative sample, removing and replacing it at the marked position each time.
2. Confirm framing, sample scale, focus, exposure, color, and shadow placement are visibly consistent across the captures.
3. Confirm opening/closing the enclosure does not leave ambient-light reflections or introduce changing glare.
4. Check that ordinary operator loading does not move the camera, sample guides, or lights.
5. Verify a live app preview does not create files or classifications; verify only the physical Pi button creates an image and batch-linked assessment.
6. Record the date, technician, camera mount/distance, light type/position, enclosure finish, sample placement, and acceptance result. Repeat this check after any physical change.

Do not treat the checklist as model accuracy validation. Keep representative samples and compare predictions under controlled conditions; consult the model owner if repeat captures vary or enclosure conditions change materially.
