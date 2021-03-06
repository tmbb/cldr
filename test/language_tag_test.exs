defmodule CldrLanguageTagTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "check that we can parse language tags" do
    check all \
      language_tag <- GenerateLanguageTag.valid_language_tag,
      max_runs: 3_000
    do
      assert {:ok, _} = Cldr.AcceptLanguage.parse(language_tag)
    end
  end

  # Tests from RFC5646 examples

  test "Simple language subtags" do
    assert {:ok, _} = Cldr.LanguageTag.parse("de")
    assert {:ok, _} = Cldr.LanguageTag.parse("fr")
    assert {:ok, _} = Cldr.LanguageTag.parse("ja")
    assert {:ok, _} = Cldr.LanguageTag.parse("i-enochian")
  end

  test "Language subtag plus Script subtag" do
    assert {:ok, _} = Cldr.LanguageTag.parse("zh-Hant")
    assert {:ok, _} = Cldr.LanguageTag.parse("zh-Hans")
    assert {:ok, _} = Cldr.LanguageTag.parse("sr-Cyrl")
    assert {:ok, _} = Cldr.LanguageTag.parse("sr-Latn")
  end

  test "Extended language subtags and their primary language subtag counterparts" do
    # Implementation does not support language subtag parsing (yet)
    # assert {:ok, _} = Cldr.LanguageTag.parse("zh-cmn-Hans-CN")
    assert {:ok, _} = Cldr.LanguageTag.parse("cmn-Hans-CN")
    # assert {:ok, _} = Cldr.LanguageTag.parse("zh-yue-HK")
    assert {:ok, _} = Cldr.LanguageTag.parse("yue-HK")
  end

  test "Language-Script-Region" do
    assert {:ok, _} = Cldr.LanguageTag.parse("zh-Hans-CN")
    assert {:ok, _} = Cldr.LanguageTag.parse("sr-Latn-RS")
  end

  test "Language-Variant" do
    # Implementation does not support language-variant,
    # only language-region-variant
    # assert {:ok, _} = Cldr.LanguageTag.parse("sl-rozaj")
    # assert {:ok, _} = Cldr.LanguageTag.parse("sl-rozaj-biske")
    # assert {:ok, _} = Cldr.LanguageTag.parse("sl-nedis")
  end

  test "Language-Region-Variant" do
    assert {:ok, _} = Cldr.LanguageTag.parse("de-CH-1901")
    assert {:ok, _} = Cldr.LanguageTag.parse("sl-IT-nedis")
  end

  test "Language-Script-Region-Variant" do
    assert {:ok, _} = Cldr.LanguageTag.parse("hy-Latn-IT-arevela")
  end

  test "Language-Region" do
    assert {:ok, _} = Cldr.LanguageTag.parse("de-DE")
    assert {:ok, _} = Cldr.LanguageTag.parse("en-US")
    assert {:ok, _} = Cldr.LanguageTag.parse("es-419")
  end

  test "Private use subtags" do
    assert {:ok, _} = Cldr.LanguageTag.parse("de-CH-x-phonebk")
    assert {:ok, _} = Cldr.LanguageTag.parse("az-Arab-x-AZE-derbend")
  end

  test "Private use registry values" do
    assert {:ok, _} = Cldr.LanguageTag.parse("x-whatever")
    assert {:ok, _} = Cldr.LanguageTag.parse("qaa-Qaaa-QM-x-southern")
    assert {:ok, _} = Cldr.LanguageTag.parse("de-Qaaa")
    assert {:ok, _} = Cldr.LanguageTag.parse("sr-Latn-QM")
    assert {:ok, _} = Cldr.LanguageTag.parse("sr-Qaaa-RS")
  end

  test "Tags that use extensions" do
    assert {:ok, _} = Cldr.LanguageTag.parse("en-US-u-islamcal")
    assert {:ok, _} = Cldr.LanguageTag.parse("zh-CN-a-myext-x-private")
    assert {:ok, _} = Cldr.LanguageTag.parse("en-a-myext-b-another")
  end

  test "Some Invalid Tags" do
    assert {:error, _} = Cldr.LanguageTag.parse("de-419-DE ")
    assert {:error, _} = Cldr.LanguageTag.parse("a-DE")

    # Implementation varies from spec.  The implementation won't error
    # on duplicate extensions - it overwrites earlier ones with later
    # ones
    # assert {:error, _} = Cldr.LanguageTag.parse("ar-a-aaa-b-bbb-a-ccc")
  end
end