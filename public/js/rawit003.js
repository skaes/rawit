function action_click() {
  var action = $(this).data("action");
  var services = $(this).data("service");
  var hosts = $(this).data("host");
  if (action == "sysadmin") {
    alert("Please contact your sysdamin and pray he's got time");
  }
  else {
    var dialog_message = "Do you really want to " + action + " " + services + " on " + hosts + "?";
    if (confirm(dialog_message)) {
      var url = "/service/" + action;
      var json = { "host": hosts, "service": services };
      var data = JSON.stringify(json);
      /* alert("posting data: " + data + " to " + url); */
      $.post(url, data, update_status).error(function() { update_status("error"); });
    }
  }
};

function get_hosts() {
  $.get('/hosts', function(summary){
    clear_status();
    $('#by-host').replaceWith(summary);
    $('#by-host .host-action').click(action_click);
  }).error(function() {
    $('#by-host').replaceWith('<div class="error bc" id="by-host">Error connecting to server.</div>');
  });
};

function get_services() {
  $.get('/services', function(summary){
    clear_status();
    $('#by-service').replaceWith(summary);
    $('#by-service .host-action').click(action_click);
  }).error(function() {
    $('#by-service').replaceWith('<div class="error bc" id="by-service">Error connecting to server.</div>');
  });
};

function get_processes() {
  $.get('/processes', function(services){
    clear_status();
    $('#by-process').replaceWith(services);
    $('#by-process .service-action').click(action_click);
  }).error(function() {
    $('#by-process').replaceWith('<div class="error bc" id="by-process">Error connecting to server.</div>');
  });
};

function get_all() {
  get_hosts();
  get_services();
  get_processes();
}

function get_selected() {
  var selected = $('.selected').data("pane");
  switch (selected) {
  case '#hosts':
    get_hosts();
    break;
  case '#services':
    get_services();
    break;
  case '#processes':
    get_processes();
    break;
  }
}

function update_loop() {
  // get_selected();
  get_all();
  window.setTimeout(update_loop, 5000);
}

/* The web socket */
var ws = null;

/* connect to the notification data stream */
function connect_notifications() {
  if ( ws == null ) {
    ws = new WebSocket("ws://" + document.location.hostname + ":9722/");
    ws.onmessage = function(evt) { update_notifications(JSON.parse(evt.data)); };
    ws.onclose = function() { ws = null; window.setTimeout(connect_notifications, 5000); };
    ws.onopen = function() { ws.send('Hi there'); };
    ws.onerror = function() { alert("websocket error"); }
  }
};

/* update the notifications */
function update_notifications(notifications) {
  var table = $('#notification-list');
  var list = $('#notification-list tr:first-child');
  for (var i = 0, len = notifications.length; i < len; ++i) {
    var e = notifications[i];
    var host = e["host"];
    var service = e["service"];
    var time = e["time"].slice(11,19);
    var message = e["message"];
    var event = e["event"];
    var new_row = $("<tr><td>" + time + "</td><td>" + host + "</td><td>" + service + "</td><td>" + event + "</td><td>" + message + "</td></tr>");
    new_row.hide().addClass("error");
    var rows = $('#notification-list tr');
    var l = rows.size() - 25;
    for (j=0; j < l; ++j) {
      rows.last().remove();
    }
    list.after(new_row);
    remove_color = function(row) { return function() {
                     window.setTimeout(function() { row.removeClass("error"); } , 10000); }; };
    new_row.fadeIn(2000, remove_color(new_row) );
  }
};

function select_tab(pane) {
  var tab = $('.tab[data-pane="' + pane + '"]');
  $('.pane').hide();
  $('.selected').removeClass("selected");
  tab.addClass("selected");
  get_selected()
  $(pane).show();
};

function click_tab() {
  var pane = $(this).data("pane");
  select_tab(pane);
  var url =  '/' + pane.replace('#','');
  history.pushState({tab: pane}, pane, url);
};

window.onpopstate = function(event) {
  var state = event.state;
  var pane = (state == null) ? '#hosts' : state["tab"];
  select_tab(pane);
};

function clear_status() {
  $('#statusarea').text('');
};

function update_status(text) {
  $('#statusarea').text(text);
}
