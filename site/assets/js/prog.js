$(function() {
	var current = $("#current");
	var nexts = $("#next");

	function updateProg() {
		current.empty();
		nexts.empty();

		fetch("prog.json").then(function(response) {
			response.json().then(function(json) {
				console.log(json);
				current.text(json["current"]);
				json["next"].forEach(function(next) {
					$("<li/>").text(next).appendTo(nexts);
				});
			});
		});
	}

	window.setInterval(updateProg, 120000);
	updateProg();
});
