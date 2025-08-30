// Minia Admin Theme JavaScript - Fixed for Rails
(function($) {
    "use strict";

    // Check if element exists before applying metisMenu
    if ($("#side-menu").length > 0) {
        $("#side-menu").metisMenu();
    }

    // Initialize Feather icons
    if (typeof feather !== 'undefined') {
        feather.replace();
    }

    // Counter animation
    function counter() {
        var counters = document.querySelectorAll(".counter-value");
        counters.forEach(function(counter) {
            function updateCount() {
                var target = +counter.getAttribute("data-target");
                var current = +counter.innerText;
                var increment = target / 250;

                if (increment < 1) {
                    increment = 1;
                }

                if (current < target) {
                    counter.innerText = (current + increment).toFixed(0);
                    setTimeout(updateCount, 1);
                } else {
                    counter.innerText = target;
                }
            }
            updateCount();
        });
    }

    // Initialize counter
    counter();

    // Sidebar menu handling
    $("#vertical-menu-btn").on("click", function(t) {
        t.preventDefault();
        $("body").toggleClass("sidebar-enable");
    });

    // Horizontal navigation handling
    function initHorizontalNav() {
        if (document.getElementById("topnav-menu-content")) {
            var links = document.getElementById("topnav-menu-content").getElementsByTagName("a");
            for (var i = 0; i < links.length; i++) {
                links[i].onclick = function(e) {
                    if (e && e.target && "#" === e.target.getAttribute("href")) {
                        e.target.parentElement.classList.toggle("active");
                        if (e.target.nextElementSibling) {
                            e.target.nextElementSibling.classList.toggle("show");
                        }
                    }
                };
            }
        }
    }

    // Initialize horizontal navigation
    initHorizontalNav();

    // Bootstrap components initialization
    $('[data-bs-toggle="tooltip"]').each(function() {
        new bootstrap.Tooltip(this);
    });

    $('[data-bs-toggle="popover"]').each(function() {
        new bootstrap.Popover(this);
    });

    $(".toast").each(function() {
        new bootstrap.Toast(this);
    });

    // Right sidebar toggle
    $(".right-bar-toggle").on("click", function(t) {
        $("body").toggleClass("right-bar-enabled");
    });

    // Theme mode toggle
    $("#mode-setting-btn").on("click", function(t) {
        var body = document.getElementsByTagName("body")[0];
        if (body.hasAttribute("data-bs-theme") && "dark" == body.getAttribute("data-bs-theme")) {
            // Switch to light mode
            document.body.setAttribute("data-bs-theme", "light");
            document.body.setAttribute("data-topbar", "light");
            document.body.setAttribute("data-sidebar", "light");
        } else {
            // Switch to dark mode
            document.body.setAttribute("data-bs-theme", "dark");
            document.body.setAttribute("data-topbar", "dark");
            document.body.setAttribute("data-sidebar", "dark");
        }
    });

    // Close right sidebar when clicking outside
    $(document).on("click", "body", function(t) {
        if ($(t.target).closest(".right-bar-toggle, .right-bar").length === 0) {
            $("body").removeClass("right-bar-enabled");
        }
    });

    // Preloader
    $(window).on("load", function() {
        $("#status").fadeOut();
        $("#preloader").delay(350).fadeOut("slow");
    });

    // Initialize waves effect if available
    if (typeof Waves !== 'undefined') {
        Waves.init();
    }

    // Language switcher
    $(".language").on("click", function(t) {
        var lang = $(this).attr("data-lang");
        if (document.getElementById("header-lang-img")) {
            var flagSrc = "";
            switch(lang) {
                case "en": flagSrc = "flags/us.jpg"; break;
                case "sp": flagSrc = "flags/spain.jpg"; break;
                case "gr": flagSrc = "flags/germany.jpg"; break;
                case "it": flagSrc = "flags/italy.jpg"; break;
                case "ru": flagSrc = "flags/russia.jpg"; break;
            }
            if (flagSrc) {
                $("#header-lang-img").attr("src", "/assets/" + flagSrc);
            }
        }
    });

    // Table check all functionality
    $("#checkAll").on("change", function() {
        $(".table-check .form-check-input").prop("checked", $(this).prop("checked"));
    });

    $(".table-check .form-check-input").change(function() {
        if ($(".table-check .form-check-input:checked").length == $(".table-check .form-check-input").length) {
            $("#checkAll").prop("checked", true);
        } else {
            $("#checkAll").prop("checked", false);
        }
    });

})(jQuery);

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    // Re-initialize Feather icons after DOM updates
    if (typeof feather !== 'undefined') {
        feather.replace();
    }
});
