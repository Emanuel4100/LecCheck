import json
import os

class Translator:
    def __init__(self, lang="he"):
        self.lang = lang
        self.translations = {}
        self.load_translations()

    def load_translations(self):
        # מוצא את הנתיב המוחלט לתיקיית locales
        base_dir = os.path.dirname(os.path.dirname(__file__))
        file_path = os.path.join(base_dir, "locales", f"{self.lang}.json")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                self.translations = json.load(f)
        except FileNotFoundError:
            print(f"Warning: Translation file not found: {file_path}")
            self.translations = {}

    def get(self, key, default=None):
        keys = key.split('.')
        val = self.translations
        for k in keys:
            if isinstance(val, dict) and k in val:
                val = val[k]
            else:
                return default if default is not None else key
        return val

translator = Translator("he")

def t(key, default=None):
    return translator.get(key, default)