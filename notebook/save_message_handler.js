define([
    'base/js/namespace'
], function(
    Jupyter
) {
    function load_handle_save_notebook_extension() {
        // iframe_source examples: "https://localhost", "https://app.onecodex.com https://localhost"
        // "https://*.onecodex.com https://*.onecodex.cloud"; all those scenarios are supported
        const source = iframe_source || "http://localhost";
        const sourceGrouped = source.includes(" ")
            ? "(" + source.replaceAll(" ", "|") + ")"
            : source;
        const rule = new RegExp(sourceGrouped.replaceAll("*", ".*"));
        window.addEventListener("message", (event) => {
            if (!event.data) {
                // Events with no data are just ignored
                return;
            }
            if (!rule.test(event.origin)) {
                console.error(`Event from unknown source (${event.origin}) : ${event.data}`);
            }
            else {
                // Message coming from a confirmed source
                if (event.data === "saveNotebook") {
                    Jupyter.notebook.save_notebook();
                }
            }
        });
    }

    return {
        load_ipython_extension: load_handle_save_notebook_extension
    };
});
