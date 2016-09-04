defmodule Number.System.Test do
  use ExUnit.Case

  test "that number_system_for with a system name returns" do
    system = Cldr.Number.System.number_system_for("en", "latn")
    assert system ==
        %Cldr.Number.System{digits: "0123456789", name: "latn", rules: nil,
             type: :numeric}
  end

  test "that number_systems_for raises when the locale is not known" do
    locale = "zzz"
    assert_raise Cldr.UnknownLocaleError, ~r/The locale "zzz" is not known./, fn ->
      Cldr.Number.System.number_systems_for(locale)
    end
  end

  test "that number_system_names_for raises when the locale is not known" do
    locale = "zzz"
    assert_raise Cldr.UnknownLocaleError, ~r/The locale "zzz" is not known./, fn ->
      Cldr.Number.System.number_system_names_for(locale)
    end
  end

  test "that number_systems_like returns a list" do
    likes = Cldr.Number.System.number_systems_like("en", "latn")
    assert is_list(likes)
    assert Enum.count(likes) > 100
  end
end