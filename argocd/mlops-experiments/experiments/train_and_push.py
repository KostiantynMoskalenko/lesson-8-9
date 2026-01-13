import os
import shutil
from pathlib import Path

import mlflow
import mlflow.sklearn
import numpy as np
from mlflow.tracking import MlflowClient
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from sklearn.datasets import load_iris
from sklearn.linear_model import SGDClassifier
from sklearn.metrics import accuracy_score, log_loss
from sklearn.model_selection import train_test_split


def push_metrics(pushgateway_url: str, run_id: str, accuracy: float, loss: float) -> None:
    registry = CollectorRegistry()

    g_acc = Gauge("mlflow_accuracy", "Model accuracy from MLflow runs", ["run_id"], registry=registry)
    g_loss = Gauge("mlflow_loss", "Model loss from MLflow runs", ["run_id"], registry=registry)

    g_acc.labels(run_id=run_id).set(float(accuracy))
    g_loss.labels(run_id=run_id).set(float(loss))

    push_to_gateway(pushgateway_url, job="mlops-experiments", registry=registry, grouping_key={"run_id": run_id})

def main() -> None:
    tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
    pushgateway_url = os.getenv("PUSHGATEWAY_URL", "http://pushgateway.monitoring.svc.cluster.local:9091")

    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment("iris-sweep")

    iris = load_iris()
    X = iris.data
    y = iris.target

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=42, stratify=y
    )

    # “learning_rate, epochs” как в задании
    learning_rates = [0.0005, 0.001, 0.01]
    epochs_list = [50, 150, 400]

    for lr in learning_rates:
        for epochs in epochs_list:
            with mlflow.start_run() as run:
                run_id = run.info.run_id

                clf = SGDClassifier(
                    loss="log_loss",
                    learning_rate="constant",
                    eta0=lr,
                    max_iter=epochs,
                    tol=None,
                    random_state=42,
                )

                clf.fit(X_train, y_train)

                probs = clf.predict_proba(X_test)
                preds = np.argmax(probs, axis=1)

                acc = accuracy_score(y_test, preds)
                loss = log_loss(y_test, probs)

                # MLflow logging
                mlflow.log_param("learning_rate", lr)
                mlflow.log_param("epochs", epochs)
                mlflow.log_metric("accuracy", float(acc))
                mlflow.log_metric("loss", float(loss))

                # model artifact
                mlflow.sklearn.log_model(clf, artifact_path="model")

                # PushGateway
                push_metrics(pushgateway_url, run_id=run_id, accuracy=acc, loss=loss)

                print(f"[run_id={run_id}] lr={lr} epochs={epochs} acc={acc:.4f} loss={loss:.4f}")

    # выбрать лучший run по accuracy и скачать модель в best_model/
    client = MlflowClient()
    exp = client.get_experiment_by_name("iris-sweep")
    if exp is None:
        raise RuntimeError("Experiment 'iris-sweep' not found")

    runs = client.search_runs(
        experiment_ids=[exp.experiment_id],
        order_by=["metrics.accuracy DESC"],
        max_results=1,
    )
    if not runs:
        raise RuntimeError("No runs found")

    best_run = runs[0]
    best_run_id = best_run.info.run_id
    print(f"\nBest run: {best_run_id} accuracy={best_run.data.metrics.get('accuracy')}")

    dst = Path(__file__).resolve().parents[1] / "best_model"
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True, exist_ok=True)

    local_path = mlflow.artifacts.download_artifacts(
        run_id=best_run_id,
        artifact_path="model",
        dst_path=str(dst),
    )
    print(f"Best model downloaded to: {local_path}")


if __name__ == "__main__":
    main()
