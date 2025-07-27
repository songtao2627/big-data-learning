"""
降级PySpark版本以兼容Java 8的脚本
"""
import subprocess
import sys

def check_java_version():
    """
    检查Java版本
    """
    try:
        result = subprocess.run(["java", "-version"], capture_output=True, text=True, shell=True)
        print("当前Java版本信息:")
        print(result.stderr)
        
        # 检查是否为Java 8
        if "1.8.0" in result.stderr:
            print("检测到Java 8，建议使用PySpark 3.3.x或3.4.x版本")
            return "java8"
        elif "11." in result.stderr or "17." in result.stderr or "21." in result.stderr:
            print("检测到Java 11或更高版本，可以使用PySpark 3.5.0")
            return "java11+"
        else:
            print("无法确定Java版本")
            return "unknown"
    except Exception as e:
        print(f"检查Java版本时出错: {e}")
        return "unknown"

def downgrade_pyspark():
    """
    降级PySpark版本
    """
    print("开始降级PySpark版本...")
    
    try:
        # 卸载当前版本的PySpark
        print("卸载当前版本的PySpark...")
        subprocess.run([sys.executable, "-m", "pip", "uninstall", "pyspark", "-y"], check=True)
        
        # 安装与Java 8兼容的PySpark版本 (3.4.3)
        print("安装PySpark 3.4.3 (与Java 8兼容)...")
        subprocess.run([sys.executable, "-m", "pip", "install", "pyspark==3.4.3"], check=True)
        
        # 验证安装
        print("验证PySpark安装...")
        result = subprocess.run([sys.executable, "-c", "import pyspark; print('PySpark版本:', pyspark.__version__)"], 
                               capture_output=True, text=True, shell=True)
        print(result.stdout)
        
        if result.returncode == 0:
            print("✅ PySpark降级成功!")
            return True
        else:
            print("❌ PySpark降级失败!")
            return False
            
    except subprocess.CalledProcessError as e:
        print(f"执行命令时出错: {e}")
        return False
    except Exception as e:
        print(f"降级PySpark时发生未知错误: {e}")
        return False

def main():
    """
    主函数
    """
    print("=== PySpark版本兼容性修复工具 ===\n")
    
    java_version = check_java_version()
    
    if java_version == "java8":
        print("\n检测到Java 8环境，正在降级PySpark版本...")
        success = downgrade_pyspark()
        
        if success:
            print("\n✅ 修复完成!")
            print("现在您可以使用本地PySpark环境了。")
            print("\n建议的测试命令:")
            print("  python -c \"from pyspark.sql import SparkSession; spark = SparkSession.builder.master('local').getOrCreate(); print(spark.range(5).collect()); spark.stop()\"")
        else:
            print("\n❌ 修复失败，请手动检查环境。")
    elif java_version == "java11+":
        print("\n您的Java版本与PySpark 3.5.0兼容，无需降级。")
    else:
        print("\n无法确定Java版本，请手动检查环境。")

if __name__ == "__main__":
    main()