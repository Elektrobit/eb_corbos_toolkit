# Break circular dependency:
# python3-jaraco.context -> python3-setuptools -> python3-jaraco.text -> python3-jaraco.context
RDEPENDS:remove = "python3-setuptools"
