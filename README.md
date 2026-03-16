# 📊 DemandCast AI — Demand Forecasting & Inventory Optimization System

> ML-powered demand predictions for retail store operations, reducing inventory waste by **$192K annually** through **64% more accurate forecasting**.

![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688?logo=fastapi&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 Problem Statement

Multi-location retail operations lose **8-15% of revenue** to food waste caused by inaccurate demand forecasting. Store managers currently use simple moving averages and manual judgment for ordering decisions, leading to:

- **Overstocking** on slow days → Food expires → Money thrown away
- **Understocking** on peak days → Empty shelves → Lost revenue

**This system solves both problems** by predicting daily item-level demand across store locations with **9.42% error** — enabling precise, data-driven inventory ordering.

---

## 📊 Results

| Model | MAE | RMSE | MAPE | R² | vs Baseline |
|-------|-----|------|------|----|-------------|
| Baseline (7-Day MA) | 721.8 | 1336.5 | 26.47% | 0.8519 | — |
| Linear Regression | 402.8 | 710.5 | 21.02% | 0.9581 | 20.6% better |
| Random Forest | 254.7 | 496.8 | 10.76% | 0.9795 | 59.4% better |
| **XGBoost** | **221.0** | **440.9** | **9.42%** | **0.9839** | **64.4% better ★** |
| LightGBM | 229.2 | 446.2 | 9.98% | 0.9835 | 62.3% better |

**Best Model: XGBoost** — predicts daily demand with only 9.42% average error.

---

## 💰 Business Impact

| Impact Area | Value | Details |
|-------------|-------|---------|
| 📉 Forecast Error Reduction | **64.4%** | vs moving average baseline |
| 🗑️ Annual Waste Reduction | **$192,000** | across 10 high-revenue stores |
| 📣 Marketing Reallocation | **$200,000+** | identified misallocated promotion spend |
| 📅 Weekend Demand Insight | **45%** | Saturday sales higher than Tuesday |
| 🏷️ Promotion Effectiveness | **42% vs 3%** | GROCERY vs BABY CARE response gap |

---

## 🏗️ Technical Architecture

```
BigQuery (3M+ transactions, SQL EDA)
    ↓
PySpark (60+ engineered features)
    ↓
XGBoost Model (9.42% MAPE, R² = 0.9839)
    ↓
FastAPI (REST API) + Streamlit (Dashboard)
    ↓
Docker (Containerized Deployment)
```

---

## 📁 Project Structure

```
demand-forecasting-system/
│
├── app/
│   ├── __init__.py              # Python package init
│   ├── main.py                  # FastAPI application (5 endpoints)
│   └── model.py                 # Model loading & prediction logic
│
├── dashboard/
│   └── app.py                   # Streamlit dashboard (5 tabs)
│
├── models/
│   ├── best_model_xgb.pkl      # Trained model file
│   └── feature_columns.json     # Feature list (60+ features)
│
├── notebooks/
│   ├── 01_EDA_BigQuery.ipynb         
│   ├── 02_Feature_Engineering.ipynb  
│   └── 03_Model_Training.ipynb       
│
├── results/
│   ├── eda/                     # EDA visualizations
│   │   ├── category_sales.png
│   │   ├── weekly_seasonality.png
│   │   ├── monthly_seasonality.png
│   │   ├── sales_trend.png
│   │   ├── promotion_impact.png
│   │   ├── store_analysis.png
│   │   └── zero_sales_analysis.png
│   ├── model_comparison.png
│   ├── feature_importance.png
│   ├── actual_vs_predicted.png
│   ├── model_results.csv
│   └── feature_importance.csv
│
├── Dockerfile                   # Container configuration
├── docker-compose.yml           # Multi-service orchestration
├── requirements.txt             # Python dependencies
└── .gitignore
```

---

## 🚀 Quick Start

### Option 1: Run with Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/anushkundu/demand-forecasting-system.git
cd demand-forecasting-system

# Build and run both API + Dashboard
docker-compose up --build

# API:       http://localhost:8000/docs
# Dashboard: http://localhost:8501
```

### Option 2: Run Locally

```bash
# Clone the repository
git clone https://github.com/anushkundu/demand-forecasting-system.git
cd demand-forecasting-system

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start API (Terminal 1)
uvicorn app.main:app --reload --port 8000

# Start Dashboard (Terminal 2 — activate venv first)
streamlit run dashboard/app.py
```

### Option 3: API Only

```bash
pip install fastapi uvicorn lightgbm scikit-learn pandas numpy pydantic
uvicorn app.main:app --reload --port 8000

# Open: http://localhost:8000/docs
```

---

## 🔌 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check — confirms API is running |
| `/health` | GET | Detailed health status |
| `/quick-predict` | POST | Simple prediction (4-5 inputs) |
| `/predict` | POST | Full prediction (all features) |
| `/model-info` | GET | Model performance and metadata |

### Quick Prediction Example

```python
import requests

response = requests.post(
    "http://localhost:8000/quick-predict",
    json={
        "yesterday_sales": 600,
        "last_week_same_day": 550,
        "weekly_average": 500,
        "day_of_week": 7,
        "is_promotion": True,
        "is_holiday": False
    }
)

print(response.json())
# {
#     "predicted_demand": 650,
#     "confidence": "medium",
#     "recommendation": "High demand — increase stock order",
#     "features_provided": 7,
#     "features_expected": 60
# }
```

### Full Prediction Example

```python
response = requests.post(
    "http://localhost:8000/predict",
    json={
        "sales_lag_1": 420,
        "sales_lag_7": 450,
        "rolling_mean_7": 410,
        "day_of_week": 7,
        "month": 12,
        "onpromotion": 5,
        "is_weekend": 1,
        "is_holiday": 0,
        "rolling_mean_14": 400,
        "rolling_mean_30": 390,
        "oil_price": 52.3,
        "store_type_encoded": 4,
        "family_encoded": 0,
        "category_avg_all_stores": 380
    }
)
print(response.json())
```

### cURL Example

```bash
curl -X POST "http://localhost:8000/quick-predict" \
  -H "Content-Type: application/json" \
  -d '{
    "yesterday_sales": 420,
    "last_week_same_day": 450,
    "weekly_average": 410,
    "day_of_week": 7,
    "is_promotion": true,
    "is_holiday": false
  }'
```

---

## 🔬 Feature Engineering

Engineered **60+ predictive features** across 4 tiers using PySpark:

| Tier | Category | Features | Examples |
|------|----------|----------|----------|
| 1 | Calendar | 19 | day_of_week, month, cyclical sin/cos encoding, is_weekend, is_december |
| 2 | Lag & Rolling | 16 | sales_lag_1/7/14/28/365, rolling_mean_7/14/30, rolling_std |
| 3 | Advanced | 15 | promotion saturation, holiday proximity, WoW/MoM/YoY momentum |
| 4 | Expert | 14 | demand regime, cross-store comparison, z-scores, CV, interactions |

### Feature Importance (Top 10)

| Rank | Feature | Importance | Business Meaning |
|------|---------|------------|------------------|
| 1 | rolling_mean_7 | 49.87% | 7-day average demand level |
| 2 | sales_lag_7 | 32.25% | Same day last week |
| 3 | category_avg_all_stores | 10.60% | Chain-wide demand signal |
| 4 | sales_lag_14 | 2.19% | 2 weeks ago sales |
| 5 | sales_lag_1 | 1.05% | Yesterday's sales |
| 6 | expanding_std | 0.93% | Long-term volatility |
| 7 | sales_lag_28 | 0.50% | Monthly cycle |
| 8 | cluster | 0.28% | Store cluster grouping |
| 9 | rolling_std_7 | 0.22% | Recent demand volatility |
| 10 | rolling_max_7 | 0.19% | Recent peak demand |

**Key Insight:** Top 3 features account for **92.7%** of prediction power — all related to recent sales history and cross-store patterns.

### Data Leakage Prevention

- All lag features use only past data via `F.lag()` 
- Rolling windows exclude current row: `rowsBetween(-N, -1)`
- Expanding windows exclude current row: `rowsBetween(unboundedPreceding, -1)`
- Train/test split is strictly temporal (no future data in training)
- Verified through manual spot-checks on random samples

---

## 📈 Key EDA Findings

| # | Finding | Business Impact |
|---|---------|-----------------|
| 1 | Saturday sales **45% higher** than Tuesday | Adjust daily order quantities by day of week → **$80K savings** |
| 2 | December **45% above** annual average | Pre-position inventory by late November → prevent stockouts |
| 3 | Promotions: GROCERY **+42%** vs BABY CARE **+3%** | Reallocate marketing budget → **$200K+ incremental revenue** |
| 4 | Top 10 stores = **55%** of total revenue | Prioritize ML deployment to high-value stores first |
| 5 | 12 of 33 categories have **>70% zero-sales days** | Exclude from ML, keep on manual ordering |
| 6 | Pre-holiday surge **+25%**, holiday drop **-60%** | Create holiday proximity features, not just binary flags |
| 7 | Oil price correlation: **0.15** | Weak but measurable — included as external feature |
| 8 | Year-over-year growth: **~8%** | Include trend feature to avoid systematic underprediction |

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Data Storage | Google BigQuery | Cloud data warehouse, SQL-based EDA |
| Data Processing | PySpark | Distributed feature engineering at scale |
| Machine Learning | XGBoost, LightGBM, scikit-learn | Model training and comparison |
| API | FastAPI | REST API for predictions |
| Dashboard | Streamlit, Plotly | Interactive visualization |
| Containerization | Docker, Docker Compose | Reproducible deployment |
| Version Control | Git, GitHub | Code management |

---

## 📓 Notebooks

| Notebook | Description | Key Output |
|----------|-------------|------------|
| `01_EDA_BigQuery.ipynb` | SQL EDA on 3M+ rows, 12 queries, 7 visualizations | Business insights, feature hypotheses |
| `02_Feature_Engineering.ipynb` | PySpark feature pipeline, 60+ features, leakage prevention | train_features.parquet, test_features.parquet |
| `03_Model_Training.ipynb` | 5 model comparison, evaluation, business impact calculation | best_model_lgbm.pkl, results |

---

## 📊 Dashboard Features

The Streamlit dashboard includes 5 interactive tabs:

| Tab | Feature |
|-----|---------|
| 🔮 Predict Demand | Enter sales data → get AI-powered forecast with confidence gauge |
| 📊 EDA Insights | Interactive EDA visualizations with business context |
| 📈 Model Performance | Model comparison charts, radar plot, downloadable results |
| 🔍 Feature Insights | Feature importance with bar, lollipop, and treemap views |
| ℹ️ About System | Architecture diagram, key results, tech stack |

---

## 🔮 Future Improvements

| Improvement | Expected Impact |
|-------------|-----------------|
| Add weather data (Open-Meteo API) | +1-2% MAPE improvement |
| Hierarchical models per store type | Better local predictions |
| Prediction intervals (confidence bands) | Inform safety stock decisions |
| Model monitoring & drift detection | Maintain accuracy over time |
| Automated retraining pipeline | Keep model fresh with new data |

---

## 📋 Requirements

```
fastapi
uvicorn
python-multipart
lightgbm
scikit-learn
pandas
numpy
streamlit
plotly
pydantic
requests
```

Python 3.10+ recommended. Tested on Python 3.12.

---

## 🧪 Testing

```bash
# Test API is running
curl http://localhost:8000/health

# Test prediction
curl -X POST http://localhost:8000/quick-predict \
  -H "Content-Type: application/json" \
  -d '{"yesterday_sales": 4200, "last_week_same_day": 4050, "weekly_average": 4100, "day_of_week": 7, "is_promotion": false, "is_holiday": false}'

# Test model info
curl http://localhost:8000/model-info
```

---

## 👤 Author

**Anush Kundu**

- 📍 Nagpur, India
- 🎓 MSc Data Science, Kingston University London
- 💼 2.5 years in retail analytics (Compass Group UK, Cognizant)
- 📧 anushkundu55@gmail.com
- 🔗 [LinkedIn](https://linkedin.com/in/anushkundu)
- 🐙 [GitHub](https://github.com/anushkundu)

### Background

This project was inspired by real-world experience at **Compass Group (London)**, where I managed demand forecasting for 100+ menu items using manual methods. The moving average approach reduced waste by 12% but left significant room for improvement. This system explores how machine learning can push accuracy further — achieving **64.4% better forecasting** than the baseline methods used in operations.

---

## 📄 License

This project is open source under the [MIT License](LICENSE).

---

<p align="center">
  <strong>📊 DemandCast AI</strong> — Built with BigQuery · PySpark · XGBoost · FastAPI · Streamlit · Docker
</p>
