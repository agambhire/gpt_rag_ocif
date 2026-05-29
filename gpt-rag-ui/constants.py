import re

APPLICATION_INSIGHTS_CONNECTION_STRING = "APPLICATIONINSIGHTS_CONNECTION_STRING"
APP_NAME = "gpt-rag-ui"

# Constants
UUID_REGEX = re.compile(
    r'^\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\s+',
    re.IGNORECASE
)

SUPPORTED_EXTENSIONS = [
    "pdf", "bmp", "jpeg", "jpg", "png", "tiff", "xlsx", "docx", "pptx",
    "md", "txt", "html", "shtml", "htm", "py", "csv", "xml", "json", "vtt"
]

REFERENCE_REGEX = re.compile(
    r'\[([^\]]+)\]\((https?://[^\s]+?)\)',
    re.IGNORECASE
)

TERMINATE_TOKEN = "TERMINATE"

DISCLAIMER_TEXT = """⚠️ **Disclaimer**

The information provided by this chatbot is intended for general guidance purposes only and does not constitute legal advice. The responses generated are not legally binding and do not supersede, replace, or override any applicable laws, regulations, rules, or official directives issued by the Office of the Commissioner of Financial Institutions (OCIF) or any other regulatory authority. For official guidance, regulatory interpretations, or compliance determinations, please refer directly to OCIF's published regulations and official communications, or consult a qualified legal or compliance professional.

---
"""