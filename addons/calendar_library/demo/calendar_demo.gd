extends Control

var cal: Calendar = Calendar.new()
var year = 2025

var months_formatted: Array[String]
var weekdays_formatted: Array[String]

var selected_date: Calendar.Date
var selected_date_label: Label

var show_weeks: bool = true
var week_number_system: Calendar.WeekNumberSystem
var show_week_number: bool = true

# -------------------------------------------------------
# 🔵 POPUP PREFAB BURADA YÜKLENİYOR
var note_popup_scene := preload("res://scenes/prefabs/note_pop_up.tscn")
var note_popup: Node
# -------------------------------------------------------

func _ready() -> void:
	UI.get_node("UIRoot").show_only_top_right_buttons()
	cal.set_first_weekday(Time.WEEKDAY_MONDAY)
	cal.week_number_system = Calendar.WeekNumberSystem.WEEK_NUMBER_FOUR_DAY
	
	selected_date = Calendar.Date.today()
	weekdays_formatted = cal.get_weekdays_formatted(Calendar.WeekdayFormat.WEEKDAY_FORMAT_SHORT)
	months_formatted = cal.get_months_formatted(Calendar.MonthFormat.MONTH_FORMAT_FULL)
	
	# -------------------------------------------------------
	# 🔵 POPUP OLUŞTUR → SAHNEYE EKLE
	note_popup = note_popup_scene.instantiate()
	add_child(note_popup)
	# popup başlangıçta kapalı olsun
	note_popup.hide()
	# -------------------------------------------------------
	
	populate_year_calendar()
	set_date_label(selected_date)


############################################################
#########   YEAR CALENDAR BUILDING
############################################################

func populate_year_calendar():
	var year_calendar = cal.get_calendar_year(year, true)
	%YearLabel.text = str(year)
	
	var month = 1
	for months in year_calendar:
		var month_container = _add_month_grid_container(month)
		
		if show_weeks:
			var weekday_label = CalendarLabel.new("")
			month_container.add_child(weekday_label)

		for weekday in weekdays_formatted:
			var weekday_label = CalendarLabel.new(weekday)
			month_container.add_child(weekday_label)
		
		var todays_date := Calendar.Date.today()

		for week in months:
			if show_weeks:
				var first_date = week[0]
				var week_number = cal.get_week_number(first_date.year, first_date.month, first_date.day)
				var week_label = CalendarLabel.new(str(week_number))
				week_label.label_settings.font_color = Color("#92a1cf")
				month_container.add_child(week_label)
				
			for date in week:
				var date_label = CalendarLabel.new(str(date.day), true)
				
				if date.month == month:
					date_label.label_settings.font_color = Color("#3a6960")
				else:
					date_label.label_settings.font_color = Color("#92a1cf")
				
				date_label.pressed.connect(_on_date_pressed.bind(date, date_label))
				month_container.add_child(date_label)
				
				if date.is_equal(selected_date):
					set_selected_state(date_label)
		
		month += 1


############################################################
#########   DATE SELECTION + POPUP AÇMA
############################################################

func _on_date_pressed(date: Calendar.Date, date_label: Label):
	set_selected_state(date_label)
	set_date_label(date)
	selected_date = date

	# -------------------------------------------------------
	# 🔵 POPUP’I AÇ — date parametresi ile
	note_popup.call("open_for_date", date)
	# -------------------------------------------------------


func set_selected_state(date_label: Label):
	if selected_date_label and selected_date_label.get_child_count() > 0:
		selected_date_label.get_child(0).queue_free()
	
	var selected_rect := ColorRect.new()
	selected_rect.size = Vector2(20, 20)
	selected_rect.position += Vector2(-4, -2)
	selected_rect.color = Color("#92a1cf")
	selected_rect.show_behind_parent = true
	
	date_label.add_child(selected_rect)
	selected_date_label = date_label


func set_date_label(date: Calendar.Date):
	%DateLabel.text = cal.get_date_formatted(date.year, date.month, date.day, "%A, %-d %B")


############################################################
#########   MONTH BUILDER
############################################################

func _add_month_grid_container(p_month: int):
	var month_container = VBoxContainer.new()
	month_container.set("theme_override_constants/separation", 10)
	
	var month_title = CalendarLabel.new(months_formatted[p_month - 1])
	month_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	month_title.label_settings.font_color = Color("#3a6960")
	month_container.add_child(month_title)
	
	var month_grid = GridContainer.new()
	month_grid.columns = 8 if show_weeks else 7
	month_grid.set("theme_override_constants/h_separation", 14)
	month_grid.set("theme_override_constants/v_separation", 6)
	month_container.add_child(month_grid)
	%YearCalendar.add_child(month_container)
	
	return month_grid


func clear_year_calendar():
	selected_date_label = null
	for child in %YearCalendar.get_children():
		child.queue_free()


############################################################
#########   OPTION BUTTON SIGNALS
############################################################

func _on_first_weekday_option_button_item_selected(index: int) -> void:
	match index:
		0: cal.set_first_weekday(Time.WEEKDAY_MONDAY)
		1: cal.set_first_weekday(Time.WEEKDAY_TUESDAY)
		2: cal.set_first_weekday(Time.WEEKDAY_WEDNESDAY)
		3: cal.set_first_weekday(Time.WEEKDAY_THURSDAY)
		4: cal.set_first_weekday(Time.WEEKDAY_FRIDAY)
		5: cal.set_first_weekday(Time.WEEKDAY_SATURDAY)
		6: cal.set_first_weekday(Time.WEEKDAY_SUNDAY)
	
	weekdays_formatted = cal.get_weekdays_formatted(Calendar.WeekdayFormat.WEEKDAY_FORMAT_SHORT)
	clear_year_calendar()
	populate_year_calendar()


func _on_week_number_system_option_button_item_selected(index: int) -> void:
	match index:
		0: cal.set_week_number_system(Calendar.WeekNumberSystem.WEEK_NUMBER_FOUR_DAY)
		1: cal.set_week_number_system(Calendar.WeekNumberSystem.WEEK_NUMBER_TRADITIONAL)
		
	clear_year_calendar()
	populate_year_calendar()


func _on_week_numbers_check_button_toggled(toggled_on: bool) -> void:
	show_weeks = toggled_on
	clear_year_calendar()
	populate_year_calendar()


func _on_year_minus_pressed() -> void:
	year -= 1
	clear_year_calendar()
	populate_year_calendar()


func _on_year_plus_pressed() -> void:
	year += 1
	clear_year_calendar()
	populate_year_calendar()


func _on_language_option_button_item_selected(index: int) -> void:
	match index:
		0: cal.set_calendar_locale("res://addons/calendar_library/demo/calendar_locale_EN.tres")
		1: cal.set_calendar_locale("res://addons/calendar_library/demo/calendar_locale_DE.tres")
		2: cal.set_calendar_locale("res://addons/calendar_library/demo/calendar_locale_ES.tres")
		3: cal.set_calendar_locale("res://addons/calendar_library/demo/calendar_locale_CN.tres")
		4: cal.set_calendar_locale("res://addons/calendar_library/demo/calendar_locale_SE.tres")
	
	weekdays_formatted = cal.get_weekdays_formatted(Calendar.WeekdayFormat.WEEKDAY_FORMAT_SHORT)
	months_formatted = cal.get_months_formatted(Calendar.MonthFormat.MONTH_FORMAT_FULL)
	
	clear_year_calendar()
	populate_year_calendar()
	set_date_label(selected_date)


############################################################
#########   CalendarLabel Helper Class
############################################################

class CalendarLabel:
	extends Label
	
	var clickable: bool = false
	signal pressed()
	
	func _init(p_text: String, p_clickable: bool = false):
		text = p_text
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_settings = LabelSettings.new()
		set_font_size()
		
		if p_clickable:
			clickable = true
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			mouse_filter = Control.MOUSE_FILTER_STOP
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if clickable:
				pressed.emit()
	
	func set_font_size(font_size: int = 12):
		label_settings.font_size = font_size
func _on_back_button_pressed():
	UI.get_node("UIRoot").change_scene_to("res://scenes/town.tscn")
