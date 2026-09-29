from pathlib import Path
import json
import re

ids = {
    "maple": ("115680050081537", "109560427488914", "81939913346542"),
    "racquetball_wood": ("88316057526797", "135637467228533", "135017228687636"),
    "terrazzo": ("121202771874633", "137724133031138", "105749773553007"),
    "porcelain_tile": ("135542603987924", "132467663009224", "104376880127220"),
    "carpet_tile": ("126209511063633", "114587835134293", "71963222800584"),
    "rubber": ("93777295951772", "89419544766877", "85867308593380"),
    "turf": ("110434921324962", "84763308048041", "106388111640017"),
    "sealed_concrete": ("118939598501809", "126520269594823", "97810093348285"),
    "ceramic_tile": ("126184103626009", "109023032528121", "121074020038747"),
    "ceramic_floor_tile": ("132181993186941", "108452738502579", "75346132703728"),
    "vinyl": ("137016261479465", "132467663009224", "71157329938638"),
    "painted_cmu": ("73914010132661", "74529868373378", "125304131314342"),
    "brick": ("71061751380163", "106108670193376", "81739995864834"),
    "gypsum": ("83085234647184", "105148116380465", "79559158963357"),
    "metal_panel": ("119546250161432", "130950894419275", "78997218462553"),
    "precast": ("140362294900296", "126520269594823", "103731185018538"),
    "acoustic_ceiling": ("74504063907005", "96924420037546", "110866543862913"),
    "mosaic_green": ("116682509188652", "77153283278015", "116139697584259"),
    "steel": ("124080354635515", "130950894419275", "74843447803064"),
    "mullion_aluminum": ("79237438772328", "96715336119497", "120577523437453"),
    "stainless": ("91470726429340", "110244039569304", "134128261887917"),
    "door_wood": ("75146815085481", "87900524753415", "133171298613584"),
    "door_paint": ("136989871078767", "133238565681457", "83553921069270"),
    "wood_cap_rail": ("92874150765104", "87900524753415", "122408873463919"),
    "court_green_paint": ("130890933128176", "85560496249540", "102368861586649"),
    "court_gold_paint": ("81202424403635", "133238565681457", "113811037210637"),
    "bleacher_green": ("94239505522923", "85560496249540", "79872805115337"),
    "bleacher_gold": ("86868049965059", "133238565681457", "83553921069270"),
    "sign_paint": ("74747854863990", "85560496249540", "128889279786109"),
}

p = Path("src/ReplicatedStorage/RAC/Materials.luau")
text = p.read_text(encoding="utf-8")


def patch_block(src: str, key: str, c: str, n: str, r: str) -> str:
    pat = re.compile(
        rf"({key} = \{{.*?)assetId = [^,\n]+,\s*normalAssetId = [^,\n]+,\s*roughnessAssetId = [^,\n]+,",
        re.S,
    )
    m = pat.search(src)
    if not m:
        raise SystemExit("no block " + key)
    block = m.group(0)
    block = re.sub(r"assetId = [^,\n]+", f'assetId = "rbxassetid://{c}"', block, count=1)
    block = re.sub(r"normalAssetId = [^,\n]+", f'normalAssetId = "rbxassetid://{n}"', block, count=1)
    block = re.sub(
        r"roughnessAssetId = [^,\n]+", f'roughnessAssetId = "rbxassetid://{r}"', block, count=1
    )
    return src[: m.start()] + block + src[m.end() :]


for k, (c, n, r) in ids.items():
    text = patch_block(text, k, c, n, r)
p.write_text(text, encoding="utf-8")
print("patched Materials.luau", len(ids))

ms = Path("src/MaterialService")
for k, (c, n, r) in ids.items():
    fp = ms / f"RAC_{k}.model.json"
    d = json.loads(fp.read_text(encoding="utf-8")) if fp.exists() else {"className": "MaterialVariant", "properties": {}}
    props = d.setdefault("properties", {})
    props["Name"] = "RAC_" + k
    props["ColorMap"] = f"rbxassetid://{c}"
    props["NormalMap"] = f"rbxassetid://{n}"
    props["RoughnessMap"] = f"rbxassetid://{r}"
    fp.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")

assets = json.loads(Path("art/materials/assets.json").read_text(encoding="utf-8"))
for k, (c, n, r) in ids.items():
    assets.setdefault(k, {})
    assets[k]["assetId"] = f"rbxassetid://{c}"
    assets[k]["normalAssetId"] = f"rbxassetid://{n}"
    assets[k]["roughnessAssetId"] = f"rbxassetid://{r}"
Path("art/materials/assets.json").write_text(json.dumps(assets, indent=2) + "\n", encoding="utf-8")
print("variants+assets ok")
