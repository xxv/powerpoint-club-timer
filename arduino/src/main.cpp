#include <Arduino.h>
#include <FastLED.h>

#define SEC_IN_MS(N) (N * 1000)
#define MIN_IN_MS(N) (N * 60000)

struct timer_square {
  CRGB color;
  long start_ms;
  long end_ms;
  long end_notify_ms;
};

// Configuration constants
const static uint8_t NUM_LEDS = 5;
const static uint8_t SECONDS_PER_SQUARE = 60;
const static uint8_t FEEDBACK_PULSE_MS = 255;
const static CRGB PULSE_COLOR = CRGB(20, 20, 20);

const static timer_square squares[] = {
  { .color = CRGB::Green, .start_ms = 0, .end_ms = MIN_IN_MS(1) },
  { .color = CRGB::Green, .start_ms = MIN_IN_MS(1),
    .end_ms = MIN_IN_MS(2) },
  { .color = CRGB::Green, .start_ms = MIN_IN_MS(2), .end_ms = MIN_IN_MS(3),
    .end_notify_ms = MIN_IN_MS(2) + SEC_IN_MS(30) },

  { .color = CRGB::Yellow, .start_ms = MIN_IN_MS(3), .end_ms = MIN_IN_MS(4) },
  { .color = CRGB::Yellow, .start_ms = MIN_IN_MS(4), .end_ms = MIN_IN_MS(5),
    .end_notify_ms = MIN_IN_MS(4) + SEC_IN_MS(30) }
};

// runtime state
CRGB leds[NUM_LEDS];
long counter = 0;
size_t i;


void reset_counter() {
  counter = 0;
}

void setup() {
  FastLED.addLeds<APA102, MOSI, SCK, BGR>(leds, NUM_LEDS);
  FastLED.setDither(0);
  reset_counter();
  FastLED.clear(true);
}

void loop() {
  EVERY_N_MILLIS(8) { // 125 FPS
    for (i = 0; i < NUM_LEDS; i++) {
      leds[i] = squares[i].color;

      // dim the squares based on the counter
      if (counter >= squares[i].start_ms && counter < squares[i].end_ms) {
        fract8 fade = (256 * (counter - squares[i].start_ms))
          / (squares[i].end_ms - squares[i].start_ms);
        leds[i].fadeToBlackBy(lerp8by8(0, 255, fade));

        if (squares[i].end_notify_ms && counter >= squares[i].end_notify_ms) {
          fract8 end_fade = (256 * (counter - squares[i].end_notify_ms))
            / (squares[i].end_ms - squares[i].end_notify_ms);

          leds[i] = leds[i].lerp8(leds[i] + PULSE_COLOR, map8(sin8((counter / 10) % 256), 0, end_fade));
        }
      } else if (counter >= squares[i].end_ms) {
        leds[i] = CRGB::Black;
      }
    }

    if (counter < FEEDBACK_PULSE_MS) {
      for (i = 0; i < NUM_LEDS; i++) {
        leds[i] = blend(leds[i], leds[i] + PULSE_COLOR, sin8(counter % 256));
      }
    }

    FastLED.show();
  } // each frame

  EVERY_N_MILLIS(1) {
    counter += 1;
  }
}
