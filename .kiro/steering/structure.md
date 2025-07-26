# Project Structure & Organization

## Root Directory Layout

```
big-data-learning-platform/
├── .git/                          # Git version control
├── .gitignore                     # Git ignore patterns
├── .kiro/                         # Kiro AI assistant configuration
│   ├── steering/                  # AI guidance rules
│   ├── specs/                     # Feature specifications
│   └── hooks/                     # Automation hooks
├── big-data-learning/             # Main learning platform
└── README.md                      # Project overview
```

## Main Platform Structure

```
big-data-learning/
├── .kiro/                         # Platform-specific Kiro config
├── data/                          # Datasets organized by size
│   ├── sample/                    # Small datasets for testing
│   ├── medium/                    # Medium-sized datasets
│   ├── large/                     # Large datasets for advanced exercises
│   └── datasets_description.md    # Dataset documentation
├── notebooks/                     # Learning materials
│   ├── 01-spark-basics/          # Spark fundamentals
│   ├── 02-spark-sql/             # SQL and structured data
│   ├── 03-spark-streaming/       # Real-time processing
│   ├── 04-projects/              # Practical projects
│   ├── 05-flink/                 # Flink learning materials
│   ├── index.md                  # Learning materials index
│   ├── learning_path.md          # Structured learning guide
│   └── pyspark_config.py         # PySpark configuration
├── scripts/                       # Management and utility scripts
│   ├── start_environment.ps1     # Environment startup
│   ├── stop_environment.ps1      # Environment shutdown
│   ├── health_check.ps1          # System health verification
│   ├── verify_environment.ps1    # Complete environment test
│   ├── troubleshoot.ps1          # Diagnostic tools
│   ├── manage_environment.ps1    # Advanced management
│   ├── quick_start.ps1           # Rapid setup
│   ├── data_generator.py         # Sample data creation
│   ├── jupyter_startup.sh        # Jupyter initialization
│   ├── jupyter_notebook_config.py # Jupyter configuration
│   ├── auto_save_extension.py    # Auto-save functionality
│   └── spark-defaults.conf       # Spark default settings
├── docker-compose.yml            # Container orchestration
├── docker-daemon.json           # Docker daemon configuration
├── setup_local_environment.ps1  # Initial setup script
├── start.bat                     # Quick start batch file
└── README.md                     # Platform documentation
```

## Learning Materials Organization

### Notebooks Structure
- **Sequential numbering**: 01-, 02-, 03- for logical progression
- **Topic-based folders**: Each major topic has its own directory
- **Mixed formats**: .ipynb for interactive code, .md for documentation
- **Bilingual support**: Chinese primary documentation, English code comments

### Projects Structure
```
04-projects/
├── log-analysis/                 # Server log analysis project
│   ├── README.md                # Project overview
│   ├── log_analysis.ipynb       # Main notebook
│   ├── log_parser.py           # Utility functions
│   └── log_analysis_guide.md   # Step-by-step guide
├── recommendation-system/        # Collaborative filtering project
│   ├── README.md
│   ├── recommendation_system.ipynb
│   └── recommendation_engine.py
└── real-time-dashboard/         # Streaming dashboard project
    └── README.md
```

## Configuration Files

### Docker Configuration
- **docker-compose.yml**: Multi-service orchestration with profiles
- **docker-daemon.json**: Docker daemon optimization settings
- **Health checks**: Built-in container health monitoring

### Spark Configuration
- **spark-defaults.conf**: Default Spark settings
- **pyspark_config.py**: Python-specific Spark configuration
- **Environment variables**: Container-level Spark settings

## Naming Conventions

### Files
- **Scripts**: snake_case with .ps1 extension for PowerShell
- **Notebooks**: kebab-case for folders, descriptive names for files
- **Documentation**: README.md for overviews, descriptive .md for guides
- **Data files**: Organized by type and size, descriptive naming

### Directories
- **Numbered sequences**: For learning progression (01-, 02-, etc.)
- **Descriptive names**: Clear purpose indication
- **Consistent structure**: Similar organization across modules

## Data Organization

### Dataset Categories
- **sample/**: Small files for quick testing and learning
- **medium/**: Moderate-sized datasets for intermediate exercises
- **large/**: Big datasets for advanced distributed processing

### File Formats
- **CSV**: Structured tabular data
- **JSON**: Semi-structured and nested data
- **Parquet**: Optimized columnar format for Spark
- **Text**: Log files and unstructured data

## Development Workflow

### Environment Lifecycle
1. **Setup**: Run setup_local_environment.ps1
2. **Start**: Use start_environment.ps1 with appropriate flags
3. **Develop**: Work in Jupyter notebooks
4. **Monitor**: Check health with health_check.ps1
5. **Stop**: Clean shutdown with stop_environment.ps1

### Learning Progression
1. **Index review**: Start with notebooks/index.md
2. **Path planning**: Follow learning_path.md guidance
3. **Sequential learning**: Progress through numbered modules
4. **Project application**: Apply knowledge in practical projects
5. **Progress tracking**: Update learning_path.md progress table