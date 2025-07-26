// 自定义Jupyter JavaScript
require(['base/js/namespace'], function(Jupyter) {
    // 自动显示所有变量
    Jupyter.notebook.events.on('kernel_ready.Kernel', function() {
        console.log('Kernel ready, auto-displaying variables');
        Jupyter.notebook.kernel.execute('%config IPCompleter.greedy=True');
    });
});
