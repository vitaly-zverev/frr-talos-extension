#!/bin/bash

set -e

# Создаём виртуальное окружение (если не создано)
python3 -m venv venv
source venv/bin/activate

# Обновляем pip и ставим зависимости
pip install --upgrade pip setuptools==80 wheel

# Устанавливаем j2cli из GitHub (форк kolypto)
pip install git+https://github.com/kolypto/j2cli.git

# Патчим imp → importlib
TARGET_FILE="$(find ./venv -name cli.py)"

echo "[*] Патчим файл: $TARGET_FILE"

# Заменим 'import imp' и старую загрузку модуля
sed -i 's/^import imp/import importlib.util/' "$TARGET_FILE"

# Заменим использование imp.load_source(...)
sed -i 's/imp\.load_source([^)]*)/load_module_from_file/' "$TARGET_FILE"

# Вставим новую функцию загрузки модуля в начало файла
sed -i '1i\
def load_module_from_file(name, path):\
\n    spec = importlib.util.spec_from_file_location(name, path)\
\n    module = importlib.util.module_from_spec(spec)\
\n    spec.loader.exec_module(module)\
\n    return module\n' "$TARGET_FILE"

echo "[✓] Патч применён. Проверим версию:"
j2 --version || exit 0