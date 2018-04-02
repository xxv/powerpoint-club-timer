#include <Arduino.h>
#include <Button.h>
#include <FastLED.h>

#define SEC_IN_MS(N) (N * 1000)
#define MIN_IN_MS(N) (N * 60000)

struct timer_square {
  CRGB color;
  uint32_t start_ms;
  uint32_t end_ms;
  uint32_t end_notify_ms;
};

enum Mode { count_down, animation };

// Configuration constants
const static uint32_t LONG_PRESS_MS = 3000;
const static uint32_t ANIMATION_TIMEOUT_MS = MIN_IN_MS(10);
const static uint8_t NUM_LEDS = 5;
const static uint8_t SECONDS_PER_SQUARE = 60;
const static uint8_t FEEDBACK_PULSE_MS = 192;
const static CRGB TIMEOUT_PULSE_COLOR = CRGB(80, 0, 0);
const static CRGB FEEDBACK_PULSE_COLOR = CRGB(50, 50, 50);

const static timer_square squares[] = {
  { .color = CRGB::Yellow, .start_ms = MIN_IN_MS(4), .end_ms = MIN_IN_MS(5),
    .end_notify_ms = MIN_IN_MS(4) + SEC_IN_MS(30) },
  { .color = CRGB::Yellow, .start_ms = MIN_IN_MS(3), .end_ms = MIN_IN_MS(4) },
  { .color = CRGB::Green, .start_ms = 0, .end_ms = MIN_IN_MS(1) },
  { .color = CRGB::Green, .start_ms = MIN_IN_MS(1),
    .end_ms = MIN_IN_MS(2) },
  { .color = CRGB::Green, .start_ms = MIN_IN_MS(2), .end_ms = MIN_IN_MS(3),
    .end_notify_ms = MIN_IN_MS(2) + SEC_IN_MS(30) }
};

// runtime state
Button button(5, true, true, 20);
Mode mode = count_down;
CRGB leds[NUM_LEDS];
uint32_t counter = 0;
size_t i;
uint8_t hue;

void reset_counter() {
  counter = GET_MILLIS();
}

void check_buttons() {
  button.read();

  if (button.pressedFor(LONG_PRESS_MS)) {
    if (mode == count_down) {
      mode = animation;
    }
  } else if (button.wasPressed()) {
    mode = count_down;
    reset_counter();
  }
}

void setup() {
  FastLED.addLeds<APA102, MOSI, SCK, BGR>(leds, NUM_LEDS);
  FastLED.setDither(0);
  reset_counter();
  FastLED.clear(true);
}

uint32_t time;

void loop() {
  check_buttons();

  if (mode == count_down) {
    EVERY_N_MILLIS(8) { // 125 FPS
      time = GET_MILLIS() - counter;
      for (i = 0; i < NUM_LEDS; i++) {
        leds[i] = squares[i].color;

        // dim the squares based on the counter
        if (time >= squares[i].start_ms && time < squares[i].end_ms) {
          fract8 fade = (256 * (time - squares[i].start_ms))
            / (squares[i].end_ms - squares[i].start_ms);
          leds[i].fadeToBlackBy(lerp8by8(0, 255, fade));

          if (squares[i].end_notify_ms && time >= squares[i].end_notify_ms) {
            fract8 end_fade = (256 * (time - squares[i].end_notify_ms))
              / (squares[i].end_ms - squares[i].end_notify_ms);

            leds[i] = leds[i].lerp8(leds[i] + TIMEOUT_PULSE_COLOR, map8(sin8((time / 10) % 256), 0, end_fade));
          }
        } else if (time >= squares[i].end_ms) {
          leds[i] = CRGB::Black;
        }
      }

      if (time < FEEDBACK_PULSE_MS) {
        for (i = 0; i < NUM_LEDS; i++) {
          leds[i] = blend(leds[i], leds[i] + FEEDBACK_PULSE_COLOR, sin8(time % 256));
        }
      }

      FastLED.show();
    } // each frame

    if (time >= ANIMATION_TIMEOUT_MS) {
      mode = animation;
    }
  } else if (mode == animation) {
    EVERY_N_MILLIS(64) { // 125 FPS
      fill_rainbow(leds, NUM_LEDS, hue, 256/NUM_LEDS);
      hue = (hue + 1) % 256;

      FastLED.show();
    } // frame
  }
}
