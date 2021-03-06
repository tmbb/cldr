defmodule Cldr do
  @moduledoc """
  Cldr provides the core functions to retrieve and manage
  the CLDR data that supports formatting and localisation.

  `Cldr` functionality is packaged into a several
  packages that each depend on this one.  These additional
  modules provide:

  * `Cldr.Number.to_string/2` for formatting numbers and
    `Cldr.Currency.to_string/2` for formatting currencies.
    These functions are contained in the hex package
    [ex_cldr_numbers](https://hex.pm/packages/ex_cldr_numbers).

  * `Cldr.List.to_string/2` for formatting lists.
    These function is contained in the hex package
    [ex_cldr_lists](https://hex.pm/packages/ex_cldr_lists).

  * `Cldr.Unit.to_string/2` for formatting SI units.
    These function is contained in the hex package
    [ex_cldr_units](https://hex.pm/packages/ex_cldr_units).

  * `Cldr.DateTime.to_string/2` for formatting of dates,
    times and datetimes. This function is contained in the
    hex package [ex_cldr_dates_times](https://hex.pm/packages/ex_cldr_dates_times).
  """

  alias Cldr.Config
  alias Cldr.Locale
  alias Cldr.Install
  alias Cldr.LanguageTag

  if Enum.any?(Config.unknown_locales()) do
    raise Cldr.UnknownLocaleError,
      "Some locales are configured that are not known to CLDR. " <>
      "Compilation cannot continue until the configuration includes only " <>
      "locales known in CLDR.\n\n" <>
      "Configured locales: #{inspect Config.requested_locales()}\n" <>
      "Gettext locales:    #{inspect Config.gettext_locales()}\n" <>
      "Unknown locales:    " <>
      "#{IO.ANSI.red()}#{inspect Config.unknown_locales()}" <>
      "#{IO.ANSI.default_color()}\n"
  end

  @warn_if_greater_than 100
  @known_locale_count Enum.count(Config.known_locales())
  @locale_string if @known_locale_count > 1, do: "locales ", else: "locale "
  IO.puts "Generating Cldr for #{@known_locale_count} " <>
    @locale_string <>
    "#{inspect Config.known_locales, limit: 5} with " <>
    "default locale #{inspect Config.default_locale()}"
  if @known_locale_count > @warn_if_greater_than do
    IO.puts "Please be patient, generating functions for many locales " <>
    "can take some time"
  end

  # Ensure locales are all installed.  We do this once during
  # compilation of `Cldr` because this is the module we define
  # as the root of the dependency tree.
  Install.install_known_locales

  @doc """
  Returns the directory path name where the CLDR json data
  is kept.
  """
  @data_dir Config.client_data_dir()
  @spec data_dir :: String.t
  def data_dir do
    @data_dir
  end

  @doc """
  Returns the version of the CLDR repository as a tuple

  ## Example

      iex> Cldr.version
      {31, 0, 1}

  """
  @version Config.version()
  |> String.split(".")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple

  @spec version :: {non_neg_integer, non_neg_integer, non_neg_integer}
  def version do
    @version
  end

  @doc """
  Return the current locale to be used for `Cldr` functions that
  take an optional locale parameter for which a locale is not supplied.
  """
  @spec get_current_locale :: LanguageTag.t
  def get_current_locale do
    Process.get(:cldr, default_locale())
  end

  @doc """
  Set the current locale to be used for `Cldr` functions that
  take an optional locale parameter for which a locale is not supplied.
  """
  @spec set_current_locale(String.t | LanguageTag.t) :: LanguageTag.t
  def set_current_locale(locale) when is_binary(locale) do
    case Cldr.Locale.new(locale) do
      {:ok, language_tag} -> set_current_locale(language_tag)
      {:error, reason} -> {:error, reason}
    end
  end

  def set_current_locale(%{} = language_tag) do
    Process.put(:cldr, language_tag)
  end

  @doc """
  Returns the default `locale`.

  ## Example

      iex> Cldr.default_locale()
      %Cldr.LanguageTag{canonical_locale_name: "en-Latn-001",
        cldr_locale_name: "en-001", extensions: %{}, language: "en",
        locale: [], private_use: [], rbnf_locale_name: "en", region: "001",
        requested_locale_name: "en-001", script: "Latn", transform: %{},
        variant: nil}

  """
  @default_locale Config.default_locale() |> Cldr.Config.canonical_language_tag!
  @spec default_locale :: LanguageTag.t
  def default_locale do
    @default_locale
  end

  @doc """
  Returns the default region when a locale
  does not specify one and none can be inferred.

  ## Example

      iex> Cldr.default_region()
      "001"

  """
  @spec default_region :: String.t
  def default_region do
    default_locale()
    |> Map.get(:region)
  end

  @doc """
  Returns a list of all the locale names defined in
  the CLDR repository.

  Note that not necessarily all of these locales are
  available since functions are only generated for configured
  locales which is most cases will be a subset of locales
  defined in CLDR.

  See also: `requested_locales/0` and `known_locales/0`
  """
  @all_locales Config.all_locales()
  @spec all_locales :: [Locale.name, ...]
  def all_locales do
    @all_locales
  end

  @doc """
  Returns a list of all requested locale names.

  The list is the combination of configured locales,
  `Gettext` locales and the default locale.

  See also `known_locales/0` and `all_locales/0`
  """
  @requested_locales Config.requested_locales()
  @spec requested_locales :: [Locale.name, ...] | []
  def requested_locales do
    @requested_locales
  end

  @doc """
  Returns a list of the known locale names.

  Known locales are those locales which
  are the subset of all CLDR locales that
  have been configured for use either
  directly in the `config.exs` file or
  in `Gettext`.
  """
  @known_locales Config.known_locales()
  @spec known_locales :: [Locale.name, ...] | []
  def known_locales do
    @known_locales
  end

  @doc """
  Returns a list of the locales names that are configured,
  but not known in CLDR.

  Since there is a compile-time exception raise if there are
  any unknown locales this function should always
  return an empty list.
  """
  @unknown_locales Config.unknown_locales()
  @spec unknown_locales :: [Locale.name, ...] | []
  def unknown_locales do
    @unknown_locales
  end

  @doc """
  Returns a list of locale names which have rules based number
  formats (RBNF).
  """
  @known_rbnf_locales Cldr.Config.known_rbnf_locales
  @spec known_rbnf_locales :: [Locale.name, ...] | []
  def known_rbnf_locales do
    @known_rbnf_locales
  end

  @doc """
  Returns a boolean indicating if the specified locale
  name is configured and available in Cldr.

  ## Examples

      iex> Cldr.known_locale?("en")
      true

      iex> Cldr.known_locale?("!!")
      false

  """
  @spec known_locale?(Locale.name) :: boolean
  def known_locale?(locale_name) when is_binary(locale_name) do
    locale_name in known_locales()
  end

  @doc """
  Returns a boolean indicating if the specified locale
  name is configured and available in Cldr and supports
  rules based number formats (RBNF).

  ## Examples

      iex> Cldr.known_rbnf_locale?("en")
      true

      iex> Cldr.known_rbnf_locale?("!!")
      false

  """
  @spec known_rbnf_locale?(Locale.name) :: boolean
  def known_rbnf_locale?(locale_name) when is_binary(locale_name) do
    locale_name in known_rbnf_locales()
  end

  @doc """
  Returns either the `locale_name` or `false` based upon
  whether the locale name is configured in `Cldr`.

  ## Examples

      iex> Cldr.known_locale "en-AU"
      "en-AU"

      iex> Cldr.known_locale "en-SA"
      false

  """
  @spec known_locale(Locale.name) :: String.t | false
  def known_locale(locale_name) when is_binary(locale_name) do
    if known_locale?(locale_name) do
      locale_name
    else
      false
    end
  end

  @doc """
  Returns either the locale name or nil based upon
  whether the locale name is configured in `Cldr`.

  ## Examples

      iex> Cldr.known_locale "en-AU"
      "en-AU"

      iex> Cldr.known_locale "en-SA"
      false

  """
  @spec known_rbnf_locale(Locale.name) :: String.t | false
  def known_rbnf_locale(locale_name) when is_binary(locale_name) do
    if known_rbnf_locale?(locale_name) do
      locale_name
    else
      false
    end
  end

  @doc """
  Returns an `{:ok, locale}` or `{:error, {exception, message}}` tuple
  depending on whether the locale is valid and known in the current
  configuration.

  ## Examples

      iex> Cldr.validate_locale "en"
      {:ok,
       %Cldr.LanguageTag{canonical_locale_name: "en-Latn-US", cldr_locale_name: "en",
        extensions: %{}, language: "en", locale: [], private_use: [],
        rbnf_locale_name: "en", region: "US", requested_locale_name: "en",
        script: "Latn", transform: %{}, variant: nil}}

      iex> Cldr.validate_locale Cldr.default_locale
      {:ok,
       %Cldr.LanguageTag{canonical_locale_name: "en-Latn-001",
        cldr_locale_name: "en-001", extensions: %{}, language: "en", locale: [],
        private_use: [], rbnf_locale_name: "en", region: "001",
        requested_locale_name: "en-001", script: "Latn", transform: %{},
        variant: nil}}

      iex> Cldr.validate_locale "zzz"
      {:error, {Cldr.UnknownLocaleError, "The locale \\"zzz\\" is not known."}}

  """
  @spec validate_locale(Locale.name | LanguageTag.t) ::
    {:ok, String.t} | {:error, {Exception.t, String.t}}

  def validate_locale(locale_name) when is_binary(locale_name) do
    locale_name
    |> Cldr.Locale.new
    |> validate_locale
  end

  def validate_locale(%LanguageTag{cldr_locale_name: nil} = locale) do
    {:error, Locale.locale_error(locale)}
  end

  def validate_locale(%LanguageTag{} = language_tag) do
    {:ok, language_tag}
  end

  def validate_locale(locale) do
    {:error, Locale.locale_error(locale)}
  end

  @doc """
  Returns a boolean indicating if the specified locale
  is available in CLDR.

  The return value depends on whether the locale is
  defined in the CLDR repository.  It does not necessarily
  mean the locale is configured for Cldr.  See also
  `Cldr.known_locale?/1`.

  ## Examples

      iex> Cldr.available_locale? "en-AU"
      true

      iex> Cldr.available_locale? "en-SA"
      false

  """
  @spec available_locale?(Locale.name | LanguageTag.t) :: boolean
  def available_locale?(locale) when is_binary(locale) do
    locale in Config.all_locales()
  end

  def available_locale?(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    available_locale?(cldr_locale_name)
  end

  @doc """
  Returns a list of strings representing the calendars known to `Cldr`.

  ## Example

      iex> Cldr.known_calendars
      ["buddhist", "chinese", "coptic", "dangi", "ethiopic", "ethiopic_amete_alem",
       "gregorian", "hebrew", "indian", "islamic", "islamic_civil", "islamic_rgsa",
       "islamic_tbla", "islamic_umalqura", "japanese", "persian", "roc"]

  """
  @known_calendars Cldr.Config.known_calendars
  @spec known_calendars :: [String.t, ...] | []
  def known_calendars do
    @known_calendars
  end

  @doc """
  Returns a list of strings representing the currencies known to `Cldr`.

  ## Example

      iex> Cldr.known_currencies
      ["ADP", "AED", "AFA", "AFN", "ALK", "ALL", "AMD", "ANG", "AOA", "AOK", "AON",
       "AOR", "ARA", "ARL", "ARM", "ARP", "ARS", "ATS", "AUD", "AWG", "AZM", "AZN",
       "BAD", "BAM", "BAN", "BBD", "BDT", "BEC", "BEF", "BEL", "BGL", "BGM", "BGN",
       "BGO", "BHD", "BIF", "BMD", "BND", "BOB", "BOL", "BOP", "BOV", "BRB", "BRC",
       "BRE", "BRL", "BRN", "BRR", "BRZ", "BSD", "BTN", "BUK", "BWP", "BYB", "BYN",
       "BYR", "BZD", "CAD", "CDF", "CHE", "CHF", "CHW", "CLE", "CLF", "CLP", "CNX",
       "CNY", "COP", "COU", "CRC", "CSD", "CSK", "CUC", "CUP", "CVE", "CYP", "CZK",
       "DDM", "DEM", "DJF", "DKK", "DOP", "DZD", "ECS", "ECV", "EEK", "EGP", "ERN",
       "ESA", "ESB", "ESP", "ETB", "EUR", "FIM", "FJD", "FKP", "FRF", "GBP", "GEK",
       "GEL", "GHC", "GHS", "GIP", "GMD", "GNF", "GNS", "GQE", "GRD", "GTQ", "GWE",
       "GWP", "GYD", "HKD", "HNL", "HRD", "HRK", "HTG", "HUF", "IDR", "IEP", "ILP",
       "ILR", "ILS", "INR", "IQD", "IRR", "ISJ", "ISK", "ITL", "JMD", "JOD", "JPY",
       "KES", "KGS", "KHR", "KMF", "KPW", "KRH", "KRO", "KRW", "KWD", "KYD", "KZT",
       "LAK", "LBP", "LKR", "LRD", "LSL", "LTL", "LTT", "LUC", "LUF", "LUL", "LVL",
       "LVR", "LYD", "MAD", "MAF", "MCF", "MDC", "MDL", "MGA", "MGF", "MKD", "MKN",
       "MLF", "MMK", "MNT", "MOP", "MRO", "MTL", "MTP", "MUR", "MVP", "MVR", "MWK",
       "MXN", "MXP", "MXV", "MYR", "MZE", "MZM", "MZN", "NAD", "NGN", "NIC", "NIO",
       "NLG", "NOK", "NPR", "NZD", "OMR", "PAB", "PEI", "PEN", "PES", "PGK", "PHP",
       "PKR", "PLN", "PLZ", "PTE", "PYG", "QAR", "RHD", "ROL", "RON", "RSD", "RUB",
       "RUR", "RWF", "SAR", "SBD", "SCR", "SDD", "SDG", "SDP", "SEK", "SGD", "SHP",
       "SIT", "SKK", "SLL", "SOS", "SRD", "SRG", "SSP", "STD", "SUR", "SVC", "SYP",
       "SZL", "THB", "TJR", "TJS", "TMM", "TMT", "TND", "TOP", "TPE", "TRL", "TRY",
       "TTD", "TWD", "TZS", "UAH", "UAK", "UGS", "UGX", "USD", "USN", "USS", "UYI",
       "UYP", "UYU", "UZS", "VEB", "VEF", "VND", "VNN", "VUV", "WST", "XAF", "XAG",
       "XAU", "XBA", "XBB", "XBC", "XBD", "XCD", "XDR", "XEU", "XFO", "XFU", "XOF",
       "XPD", "XPF", "XPT", "XRE", "XSU", "XTS", "XUA", "XXX", "YDD", "YER", "YUD",
       "YUM", "YUN", "YUR", "ZAL", "ZAR", "ZMK", "ZMW", "ZRN", "ZRZ", "ZWD", "ZWL",
       "ZWR"]

  """
  @known_currencies Cldr.Config.known_currencies
  @spec known_currencies :: [String.t, ...] | []
  def known_currencies do
    @known_currencies
  end

  @doc """
  Returns a list of strings representing the number systems known to `Cldr`.

  ## Example

      iex> Cldr.known_number_systems
      ["adlm", "ahom", "arab", "arabext", "armn", "armnlow", "bali", "beng", "bhks",
       "brah", "cakm", "cham", "cyrl", "deva", "ethi", "fullwide", "geor", "grek",
       "greklow", "gujr", "guru", "hanidays", "hanidec", "hans", "hansfin", "hant",
       "hantfin", "hebr", "hmng", "java", "jpan", "jpanfin", "kali", "khmr", "knda",
       "lana", "lanatham", "laoo", "latn", "lepc", "limb", "mathbold", "mathdbl",
       "mathmono", "mathsanb", "mathsans", "mlym", "modi", "mong", "mroo", "mtei",
       "mymr", "mymrshan", "mymrtlng", "newa", "nkoo", "olck", "orya", "osma",
       "roman", "romanlow", "saur", "shrd", "sind", "sinh", "sora", "sund", "takr",
       "talu", "taml", "tamldec", "telu", "thai", "tibt", "tirh", "vaii", "wara"]

  """
  @known_number_systems Cldr.Config.known_number_systems
  @spec known_number_systems :: [String.t, ...] | []
  def known_number_systems do
    @known_number_systems
  end

end