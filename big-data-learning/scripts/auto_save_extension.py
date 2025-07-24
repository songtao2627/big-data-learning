"""
Jupyter Notebook自动保存扩展
用于自动保存笔记本并记录版本历史
"""

import os
import json
import shutil
import datetime
from notebook.utils import url_path_join
from notebook.base.handlers import IPythonHandler

# 配置
BACKUP_DIR = os.path.join(os.path.expanduser('~'), 'work', '.backups')
MAX_BACKUPS = 10  # 每个笔记本保留的最大备份数量
BACKUP_INTERVAL = 300  # 备份间隔（秒）

# 确保备份目录存在
if not os.path.exists(BACKUP_DIR):
    os.makedirs(BACKUP_DIR)

def _backup_notebook(notebook_path):
    """
    备份笔记本文件
    """
    if not os.path.exists(notebook_path):
        return False
    
    # 提取笔记本名称
    notebook_name = os.path.basename(notebook_path)
    notebook_dir = os.path.dirname(notebook_path)
    
    # 创建备份目录
    backup_subdir = os.path.join(BACKUP_DIR, notebook_name.replace('.ipynb', ''))
    if not os.path.exists(backup_subdir):
        os.makedirs(backup_subdir)
    
    # 创建带时间戳的备份文件名
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_filename = f"{notebook_name.replace('.ipynb', '')}_{timestamp}.ipynb"
    backup_path = os.path.join(backup_subdir, backup_filename)
    
    # 复制文件
    shutil.copy2(notebook_path, backup_path)
    
    # 清理旧备份
    backups = sorted([f for f in os.listdir(backup_subdir) if f.endswith('.ipynb')])
    if len(backups) > MAX_BACKUPS:
        for old_backup in backups[:-MAX_BACKUPS]:
            os.remove(os.path.join(backup_subdir, old_backup))
    
    return True

class AutoSaveHandler(IPythonHandler):
    """
    处理自动保存请求的处理程序
    """
    def get(self):
        notebook_path = self.get_argument('notebook_path', '')
        if notebook_path:
            success = _backup_notebook(notebook_path)
            self.finish(json.dumps({'success': success}))
        else:
            self.finish(json.dumps({'success': False, 'error': 'No notebook path provided'}))

def load_jupyter_server_extension(nb_server_app):
    """
    加载Jupyter服务器扩展
    """
    web_app = nb_server_app.web_app
    host_pattern = '.*$'
    route_pattern = url_path_join(web_app.settings['base_url'], '/auto_save')
    web_app.add_handlers(host_pattern, [(route_pattern, AutoSaveHandler)])
    nb_server_app.log.info("Auto-save extension loaded")

# 客户端JavaScript代码
def _jupyter_nbextension_paths():
    return [dict(
        section="notebook",
        src="static",
        dest="auto_save",
        require="auto_save/main")]

# 创建客户端JavaScript文件
os.makedirs(os.path.join(os.path.dirname(__file__), 'static'), exist_ok=True)
with open(os.path.join(os.path.dirname(__file__), 'static', 'main.js'), 'w') as f:
    f.write("""
define([
    'base/js/namespace',
    'jquery',
    'base/js/utils'
], function(Jupyter, $, utils) {
    function load_ipython_extension() {
        console.log('Auto-save extension loaded');
        
        // 定期自动保存
        setInterval(function() {
            if (Jupyter.notebook) {
                Jupyter.notebook.save_notebook();
                console.log('Notebook auto-saved');
                
                // 调用服务器端备份
                var notebookPath = Jupyter.notebook.notebook_path;
                var baseUrl = utils.get_body_data('baseUrl');
                var url = baseUrl + 'auto_save?notebook_path=' + encodeURIComponent(notebookPath);
                
                $.get(url, function(data) {
                    console.log('Notebook backup result:', data);
                });
            }
        }, """ + str(BACKUP_INTERVAL * 1000) + """);
    }
    
    return {
        load_ipython_extension: load_ipython_extension
    };
});
""")