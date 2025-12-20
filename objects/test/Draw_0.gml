honey.draw(0, 0, room_width, room_height);

if (keyboard_check_pressed(ord("E"))) {
	honey.call("activitytest");	
}

if (tests > 0) {
	honey.call("test", [0, 1]);
	tests--;
} else {
	if (random(1000) < 2.0) {
		tests = 240;
	}
	honey.call("update");
}