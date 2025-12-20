honey.draw(0, 0, room_width, room_height);

function updateValue(name, value) {
	var node = honey.findNode(honey.getVariableName(name));
	if (node == undefined) return;
	node.m_value = value;
}
function updateInput(name, value) {
	updateValue("input_" + name, value);
}
function handleKeyboardInput(key) {
	updateInput(string_lower(key), keyboard_check(ord(key)));	
}
string_foreach("QWERTYUIOPASDFGHJKLZXCVBNM1234567890", handleKeyboardInput);
updateInput("mouse_left", mouse_check_button(mb_left));
updateInput("mouse_right", mouse_check_button(mb_right));
updateInput("mouse_x", mouse_x);
updateInput("mouse_y", mouse_y);
updateInput("space", keyboard_check(vk_space));
updateValue("screen_size_x", room_width);
updateValue("screen_size_y", room_height);
updateValue("delta", 0.01666);

if (!m_started) {
	m_started = true;
	honey.call("start");	
}
honey.call("update");