m_honey.draw(0, 0, room_width, room_height);

var keyboardOrds = "QWERTYUIOPASDFGHJKLZXCVBNM1234567890";
for (var i = 0; i < string_length(keyboardOrds); i++) {
	var key = string_char_at(keyboardOrds, i + 1);
	m_honey.safeSetValue("input_" + string_lower(key), keyboard_check(ord(key)))
}
m_honey.safeSetValue("input_mouse_left", mouse_check_button(mb_left));
m_honey.safeSetValue("input_mouse_left_up", mouse_check_button_released(mb_left));
m_honey.safeSetValue("input_mouse_right", mouse_check_button(mb_right));
m_honey.safeSetValue("input_mouse_right_up", mouse_check_button_released(mb_right));
m_honey.safeSetValue("input_mouse_x", mouse_x);
m_honey.safeSetValue("input_mouse_y", mouse_y);
m_honey.safeSetValue("input_space", keyboard_check(vk_space));
m_honey.safeSetValue("screen_size_x", room_width);
m_honey.safeSetValue("screen_size_y", room_height);
m_honey.safeSetValue("delta", 0.01666);

if (!m_started) {
	m_started = true;
	m_honey.call("start");	
}
m_honey.call("update");