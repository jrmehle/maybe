# Pagy 43 initializer. The extras (overflow, array) were folded into core.
#
# Behavior note: an out-of-range page now renders an empty page. It used to
# fall back to the last page (`overflow: :last_page`), which Pagy 43 dropped.
# See https://ddnexus.github.io/pagy/guides/upgrade-guide/
Pagy::OPTIONS.freeze
