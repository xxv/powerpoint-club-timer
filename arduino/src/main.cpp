#include <Arduino.h>
#include <Button.h>
#include <EEPROM.h>
#include <FastLED.h>

#define SEC_IN_MS(N) (N * 1000l)
#define MIN_IN_MS(N) (N * 60000l)

struct timer_square {
  CRGB color;
  uint32_t start_ms;
  uint32_t end_ms;
  uint32_t end_notify_ms;
};

enum Mode { count_down, config, animation };
enum ConfigMode { cfg_brightness, cfg_pattern };
enum Pattern { pat_rainbow, pat_pop, pat_solid, PATTERN_COUNT };

// Configuration constants
const static uint8_t TIME_SCALE = 1; // 1 is realtime; 10 is 10x fast
const static uint32_t CONFIG_LONG_PRESS_MS = SEC_IN_MS(2);
const static uint32_t LONG_PRESS_MS = SEC_IN_MS(3);
const static uint32_t CONFIG_TIMEOUT_MS = SEC_IN_MS(10);
const static uint32_t ANIMATION_TIMEOUT_MS = MIN_IN_MS(10);
const static uint8_t NUM_LEDS = 5;
const static uint8_t SECONDS_PER_SQUARE = 60;
const static uint8_t FEEDBACK_PULSE_MS = 192;
const static CRGB TIMEOUT_PULSE_COLOR = CRGB(80, 80, 80);
const static uint8_t TIMEOUT_PULSE_SPEED = 5;
const static CRGB FEEDBACK_PULSE_COLOR = CRGB(50, 50, 50);
const static uint8_t EEPROM_BRIGHTNESS = 0;
const static uint8_t EEPROM_PATTERN = 1;

const static uint8_t BRIGHTNESS_LEVELS[] = { 255, 32, 64, 128 };

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
ConfigMode config_mode;
Pattern pattern = pat_rainbow;

CRGB leds[NUM_LEDS];
uint32_t counter = 0;
uint32_t config_timer = 0;
size_t i;
uint8_t brightness_level;
bool button_handled = false;

uint8_t hue = 0;
CRGB pop_color = CHSV(random8(), 255, 255);
uint8_t pop_fade = 0;
uint8_t pop_led = random8(NUM_LEDS);

// config
bool cursor_blink = false;

void reset_counter() {
  counter = GET_MILLIS();
}

void reset_config_timer() {
  config_timer = GET_MILLIS();
}

void set_mode(Mode new_mode) {
  mode = new_mode;

  switch (new_mode) {
    case config:
      reset_config_timer();
      break;
    case count_down:
      reset_counter();
      break;
    case animation:
      break;
  }
}

void check_buttons() {
  button.read();

  if (mode == animation || mode == count_down) {
    if (!button_handled && button.pressedFor(LONG_PRESS_MS)) {
      if (mode == count_down) {
        set_mode(config);
        button_handled = true;
      }
    } else if (button.wasPressed()) {
      set_mode(count_down);
    }
  } else if (mode == config) {
    if (!button_handled && button.pressedFor(CONFIG_LONG_PRESS_MS)) {
      switch (config_mode) {
        case cfg_pattern:
          config_mode = cfg_brightness;
          break;
        case cfg_brightness:
          config_mode = cfg_pattern;
          break;
      }

      reset_config_timer();
      button_handled = true;
    } else if (!button_handled && button.wasReleased()) {
      if (config_mode == cfg_brightness) {
        brightness_level = (brightness_level + 1) % sizeof(BRIGHTNESS_LEVELS);
        FastLED.setBrightness(BRIGHTNESS_LEVELS[brightness_level]);
        EEPROM.write(EEPROM_BRIGHTNESS, brightness_level);
      } else if (config_mode == cfg_pattern) {
        pattern = (Pattern)((pattern + 1) % 3);
        EEPROM.write(EEPROM_PATTERN, pattern);
      }
      reset_config_timer();
    }
  }

  if (button.wasReleased()) {
    button_handled = false;
  }
}

void setup() {
  FastLED.addLeds<APA102, MOSI, SCK, BGR>(leds, NUM_LEDS);
  FastLED.setDither(0);
  reset_counter();
  FastLED.clear(true);

  brightness_level = EEPROM.read(EEPROM_BRIGHTNESS);

  if (brightness_level >= sizeof(BRIGHTNESS_LEVELS)) {
    brightness_level = 0;
  }

  FastLED.setBrightness(BRIGHTNESS_LEVELS[brightness_level]);

  uint8_t pattern_load = EEPROM.read(EEPROM_PATTERN);

  if (pattern_load >= PATTERN_COUNT) {
    pattern_load = 0;
  }

  pattern = (Pattern)pattern_load;
}

uint32_t time;

void loop() {
  check_buttons();

  if (mode == count_down) {
    EVERY_N_MILLIS(8) { // 125 FPS
      time = (GET_MILLIS() - counter) * TIME_SCALE;
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

            leds[i] = leds[i].lerp8(leds[i] + TIMEOUT_PULSE_COLOR, map8(sin8((time / TIMEOUT_PULSE_SPEED) % 256), 0, end_fade));
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
      set_mode(animation);
    }
  } else if (mode == animation) {
    if (pattern == pat_rainbow) {
      EVERY_N_MILLIS(64) { // 15 FPS
        fill_rainbow(leds, NUM_LEDS, hue, 25);
        hue = (hue + 1) % 256;

        FastLED.show();
      } // frame
    } else if (pattern == pat_solid) {
      EVERY_N_MILLIS(256) {
        fill_rainbow(leds, NUM_LEDS, hue, 18);
        leds[1] = leds[2];
        leds[0] = leds[3];
        hue = (hue + 1) % 256;

        FastLED.show();
      }
    } else if (pattern == pat_pop) {
      EVERY_N_MILLIS(8) {
        FastLED.clear(false);
        leds[pop_led] = pop_color;
        leds[pop_led].fadeToBlackBy(pop_fade);

        pop_fade += 1;

        if (pop_fade == 255) {
          pop_fade = 0;
          pop_color = CHSV(random8(), 255, 255);
          pop_led = random8(NUM_LEDS);
        }
        FastLED.show();
      }
    }
  } else if (mode == config) {
    time = GET_MILLIS() - config_timer;

    if (time >= CONFIG_TIMEOUT_MS) {
      set_mode(count_down);
    }

    EVERY_N_MILLIS(500) {
      cursor_blink = !cursor_blink;
    }

    EVERY_N_MILLIS(8) {
      leds[0] = CHSV(0, 0, (config_mode == cfg_pattern &&
                            cursor_blink) ? 128 : 32);
      leds[1] = CHSV(0, 0, (config_mode == cfg_brightness &&
                            cursor_blink) ? 128 : 32);
      if (config_mode == cfg_brightness) {
        leds[2] = CHSV(0, 0, 85);
        leds[3] = CHSV(0, 0, 170);
        leds[4] = CHSV(0, 0, 255);
      } else if (config_mode == cfg_pattern) {
        leds[2] = CHSV(hue, 255, 255);
        leds[3] = pop_color;
        leds[3].fadeToBlackBy(pop_fade);
        leds[4] = CHSV(hue, 255, 255);
        if (pattern != pat_rainbow) {
          leds[2].fadeToBlackBy(224);
        }
        if (pattern != pat_pop) {
          leds[3].fadeToBlackBy(224);
        }
        if (pattern != pat_solid) {
          leds[4].fadeToBlackBy(224);
        }
      }

      hue += 1;

      pop_fade += 1;

      if (pop_fade == 255) {
        pop_fade = 0;
        pop_color = CHSV(random8(), 255, 255);
      }

      FastLED.show();
    }
  }
}
