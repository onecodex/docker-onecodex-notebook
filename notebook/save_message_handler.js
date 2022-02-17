define([
    'base/js/namespace'
], function(
    Jupyter
) {
    function load_handle_save_notebook_extension() {
        window.addEventListener("message", (event) => {
            const source = iframe_source || "http://localhost";
            if (event.origin !== source) {
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
