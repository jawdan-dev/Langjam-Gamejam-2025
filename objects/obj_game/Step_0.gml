if (keyboard_check_pressed(vk_f11)) {
	if (window_get_fullscreen()) {
		window_set_fullscreen(false);
	} else {
		window_set_fullscreen(true);
	}
}

if (os_browser == browser_not_a_browser) return;
if (m_bw == browser_width && m_bh == browser_height) return;
m_bw = browser_width;
m_bh = browser_height;

var cam = view_camera[0];
window_set_size(browser_width, browser_height);
window_center();