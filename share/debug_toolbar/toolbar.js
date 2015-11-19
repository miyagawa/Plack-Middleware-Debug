jQuery.noConflict();
jQuery(function($j) {
	var COOKIE_NAME = 'plack_debug_panel';
	$j.plDebug = function(data, klass) {
		$j.plDebug.init();
	}
	$j.extend($j.plDebug, {
		init: function() {
			var current = null;
			$j('#plDebugPanelList li a').click(function() {
				if (!this.className) {
					return false;
				}
				current = $j('#plDebug #' + this.className);
				if (current.is(':visible')) {
				    $j(document).trigger('close.plDebug');
					$j(this).parent().removeClass('active');
				} else {
					$j('.panelContent').hide(); // Hide any that are already open
					current.show();
					$j.plDebug.open();
					$j('#plDebugToolbar li').removeClass('active');
					$j(this).parent().addClass('active');
				}
				return false;
			});
			$j('#plDebug a.plDebugClose').click(function() {
				$j(document).trigger('close.plDebug');
				$j('#plDebugToolbar li').removeClass('active');
				return false;
			});
			$j('#plDebug a.remoteCall').click(function() {
				$j('#plDebugWindow').load(this.href, {}, function() {
					$j('#plDebugWindow a.plDebugBack').click(function() {
						$j(this).parent().parent().hide();
						return false;
					});
				});
				$j('#plDebugWindow').show();
				return false;
			});
			$j('#plDebugTemplatePanel a.plTemplateShowContext').click(function() {
				$j.plDebug.toggle_arrow($j(this).children('.toggleArrow'))
				$j.plDebug.toggle_content($j(this).parent().next());
				return false;
			});
			$j('#plDebugSQLPanel a.plSQLShowStacktrace').click(function() {
				$j.plDebug.toggle_content($j('.plSQLHideStacktraceDiv', $j(this).parents('tr')));
				return false;
			});
			$j('#plHideToolBarButton').click(function() {
				$j.plDebug.hide_toolbar(true);
				return false;
			});
			$j('#plShowToolBarButton').click(function() {
				$j.plDebug.show_toolbar();
				return false;
			});
			if ($j.cookie(COOKIE_NAME)) {
				$j.plDebug.hide_toolbar(false);
			} else {
				$j.plDebug.show_toolbar(false);
			}
		},
		open: function() {
			// TODO: Decide if we should remove this
		},
		toggle_content: function(elem) {
			if (elem.is(':visible')) {
				elem.hide();
			} else {
				elem.show();
			}
		},
		close: function() {
			$j(document).trigger('close.plDebug');
			return false;
		},
		hide_toolbar: function(setCookie) {
			// close any sub panels
			$j('#plDebugWindow').hide();
			// close all panels
			$j('.panelContent').hide();
			$j('#plDebugToolbar li').removeClass('active');
			// finally close toolbar
			$j('#plDebugToolbar').hide('fast');
			$j('#plDebugToolbarHandle').show();
			// Unbind keydown
			$j(document).unbind('keydown.plDebug');
			if (setCookie) {
				$j.cookie(COOKIE_NAME, 'hide', {
					path: '/',
					expires: 10
				});
			}
		},
		show_toolbar: function(animate) {
			// Set up keybindings
			$j(document).bind('keydown.plDebug', function(e) {
				if (e.keyCode == 27) {
					$j.plDebug.close();
				}
			});
			$j('#plDebugToolbarHandle').hide();
			if (animate) {
				$j('#plDebugToolbar').show('fast');
			} else {
				$j('#plDebugToolbar').show();
			}
			$j.cookie(COOKIE_NAME, null, {
				path: '/',
				expires: -1
			});
		},
		toggle_arrow: function(elem) {
			var uarr = String.fromCharCode(0x25b6);
			var darr = String.fromCharCode(0x25bc);
			elem.html(elem.html() == uarr ? darr : uarr);
		}
	});
	$j(document).bind('close.plDebug', function() {
		// If a sub-panel is open, close that
		if ($j('#plDebugWindow').is(':visible')) {
			$j('#plDebugWindow').hide();
			return;
		}
		// If a panel is open, close that
		if ($j('.panelContent').is(':visible')) {
			$j('.panelContent').hide();
			return;
		}
		// Otherwise, just minimize the toolbar
		if ($j('#plDebugToolbar').is(':visible')) {
			$j.plDebug.hide_toolbar(true);
			return;
		}
	});
});
jQuery(function() {
	jQuery.plDebug();
});
