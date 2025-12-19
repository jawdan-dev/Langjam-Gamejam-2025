honey = new Honey("test.hhll");

var val = honey.call("update");
show_debug_message("update call value: " + string(val));
tests = 0;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(font_maki);