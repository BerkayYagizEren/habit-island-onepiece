# Arayüzdeki "✓" işaretini (U+2713) taşıyan tek glifli fontu üretir.
# Çalıştırma: python3 scripts/tools/gen_check_font.py
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UNITS_PER_EM = 1000
ADVANCE = 900
CHECK_OUTLINE = [(90, 330), (210, 450), (350, 300), (690, 720), (820, 620), (360, 60)]
OUTPUT = "assets/fonts/CheckMark.ttf"
FAMILY = "HabitIslandCheck"

pen = TTGlyphPen(None)
pen.moveTo(CHECK_OUTLINE[0])
for point in CHECK_OUTLINE[1:]:
	pen.lineTo(point)
pen.closePath()
check = pen.glyph()
empty = TTGlyphPen(None).glyph()

font = FontBuilder(UNITS_PER_EM, isTTF=True)
font.setupGlyphOrder([".notdef", "check"])
font.setupCharacterMap({0x2713: "check"})
font.setupGlyf({".notdef": empty, "check": check})
font.setupHorizontalMetrics({".notdef": (ADVANCE, 0), "check": (ADVANCE, 90)})
font.setupHorizontalHeader(ascent=900, descent=-200)
font.setupNameTable({"familyName": FAMILY, "styleName": "Regular"})
font.setupOS2(sTypoAscender=900, sTypoDescender=-200, usWinAscent=900, usWinDescent=200)
font.setupPost()
font.save(OUTPUT)
