"""Signal extractors for scan-sessions."""

from .user_frustration import extract_user_frustration
from .self_correction import extract_self_correction
from .tool_errors import extract_tool_errors
from .repeated_reads import extract_repeated_reads
from .skill_outcomes import extract_skill_outcomes

ALL_EXTRACTORS = [
    ("user_frustration", extract_user_frustration),
    ("self_correction", extract_self_correction),
    ("tool_errors", extract_tool_errors),
    ("repeated_reads", extract_repeated_reads),
    ("skill_outcomes", extract_skill_outcomes),
]
