// Código M para tabela calendário calculada automaticamente, bilíngue, com estações do ano


let
    // Aplicação da função "List.Dates" à partir de seus parâmetros para construção de tabela calendário automática.
    Fonte = List.Dates(#date(1901, 1, 1), 72684, #duration(1, 0, 0, 0)),

    // --------------------------------------------------------------------------------------------------------------
    // Feridados nacionais calculados
    // --------------------------------------------------------------------------------------------------------------

    // Função para calcular a Páscoa (algoritmo de Meeus/Jones/Butcher)
    fnPascoa = (ano as number) as date =>
        let
            a = Number.Mod(ano, 19),
            b = Number.IntegerDivide(ano, 100),
            c = Number.Mod(ano, 100),
            d = Number.IntegerDivide(b, 4),
            e = Number.Mod(b, 4),
            f = Number.IntegerDivide(b + 8, 25),
            g = Number.IntegerDivide(b - f + 1, 3),
            h = Number.Mod(19 * a + b - d - g + 15, 30),
            i = Number.IntegerDivide(c, 4),
            k = Number.Mod(c, 4),
            l = Number.Mod(32 + 2 * e + 2 * i - h - k, 7),
            m = Number.IntegerDivide(a + 11 * h + 22 * l, 451),
            mes = Number.IntegerDivide(h + l - 7 * m + 114, 31),
            dia = Number.Mod(h + l - 7 * m + 114, 31) + 1,
            data = #date(ano, mes, dia)
        in
            data,

    // Lista de anos presentes na tabela calendário
    ListaAnos = List.Distinct(List.Transform(Fonte, each Date.Year(_))),

    // Geração de feriados fixos e móveis para cada ano
    FeriadosGerados =
        List.Combine(
            List.Transform(
                ListaAnos,
                (ano as number) =>
                    let
                        pascoa = fnPascoa(ano),
                        carnaval2 = Date.AddDays(pascoa, -48),
                        carnaval3 = Date.AddDays(pascoa, -47),
                        cinzas = Date.AddDays(pascoa, -46),
                        sextaSanta = Date.AddDays(pascoa, -2),
                        corpusChristi = Date.AddDays(pascoa, 60),

                        feriadosFixos = {
                            {#date(ano, 1, 1), "Confraternização Universal"},
                            {#date(ano, 4, 21), "Tiradentes"},
                            {#date(ano, 5, 1), "Dia do Trabalho"},
                            {#date(ano, 9, 7), "Independência do Brasil"},
                            {#date(ano, 10, 12), "Nossa Senhora Aparecida"},
                            {#date(ano, 11, 2), "Finados"},
                            {#date(ano, 11, 15), "Proclamação da República"},
                            {#date(ano, 12, 25), "Natal"}
                        },

                        feriadosMoveis = {
                            {carnaval2, "Carnaval (2ª-feira)"},
                            {carnaval3, "Carnaval (3ª-feira)"},
                            {cinzas, "Quarta-feira de Cinzas"},
                            {sextaSanta, "Sexta-feira Santa"},
                            {pascoa, "Páscoa"},
                            {corpusChristi, "Corpus Christi"}
                        }
                    in
                        List.Combine({feriadosFixos, feriadosMoveis})
            )
        ),

    // Tabela interna de feriados
    FeriadosTabela = Table.FromRows(FeriadosGerados, {"Data", "Feriado"}),

    // ------------------------------------------------------------------------------------------
    // Agrupando feriados por data
    // ------------------------------------------------------------------------------------------
    FeriadosTabelaUnica =
        Table.Group(
            FeriadosTabela,
            {"Data"},
            {
                {
                    "Feriado",
                    each Text.Combine([Feriado], ", "),
                    type text
                }
            }
        ),

    // Conversão da lista inicial em formato de tabela
    Tabela = Table.FromList(Fonte, Splitter.SplitByNothing(), null, null, ExtraValues.Error),

    // Renomeação da coluna original.
    Data = Table.RenameColumns(Tabela, {{"Column1", "Data"}}),

    // Tipificação da coluna original de acordo com sua natureza e finalidade.
    Tipo = Table.TransformColumnTypes(Data, {{"Data", type date}}),

    // Inclusão do ANO
    AnoAdd = Table.AddColumn(Tipo, "Ano", each Date.Year([Data]), Int64.Type),

    // Início e fim do ano
    IniciodoAno = Table.AddColumn(AnoAdd, "Início do Ano", each Date.StartOfYear([Data]), type date),
    FimdoAno = Table.AddColumn(IniciodoAno, "Fim do Ano", each Date.EndOfYear([Data]), type date),

    // ------------------------------------------------------------------------------------------------------
    // Campos relativos aos meses
    // ------------------------------------------------------------------------------------------------------
    NumMesAdd = Table.AddColumn(FimdoAno, "Mês", each Date.Month([Data]), Int64.Type),

    NomeMesAdd =
        Table.AddColumn(
            NumMesAdd,
            "Nome do Mês",
            each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Data])) &
                 Text.Start(Date.MonthName([Data]), 3),
            type text
        ),

    MesExtensoAdd =
        Table.AddColumn(
            NomeMesAdd,
            "Mês Extenso",
            each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Data])) &
                 Text.Proper(Date.MonthName([Data])),
            type text
        ),

    InicialMesAdd =
        Table.AddColumn(
            MesExtensoAdd,
            "Mês Inicial",
            each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Data])) &
                 Text.Start(Date.MonthName([Data]), 1),
            type text
        ),

    // Meses em inglês
    MonthNameEN =
        Table.AddColumn(
            InicialMesAdd,
            "Month Name",
            each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Data])) &
                 Text.Start(Date.ToText([Data], "MMMM", "en-US"), 3),
            type text
        ),

    MonthFullEN =
        Table.AddColumn(
            MonthNameEN,
            "Month Full",
            each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Data])) &
                 Text.Proper(Date.ToText([Data], "MMMM", "en-US")),
            type text
        ),

    MonthInitialEN =
        Table.AddColumn(
            MonthFullEN,
            "Month Initial",
            each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Data])) &
                 Text.Start(Date.ToText([Data], "MMMM", "en-US"), 1),
            type text
        ),

    InicioDoMes = Table.AddColumn(MonthInitialEN, "Início do Mês", each Date.StartOfMonth([Data]), type date),
    FimDoMes = Table.AddColumn(InicioDoMes, "Fim do Mês", each Date.EndOfMonth([Data]), type date),
    DiasMesAdd = Table.AddColumn(FimDoMes, "Dias do Mês", each Date.DaysInMonth([Data]), Int64.Type),

    // ----------------------------------------------------------------------------------------------------------------
    // Campos estratégicos de agrupamento e previsão
    // ----------------------------------------------------------------------------------------------------------------

    // Status dos meses do ano atual
    AddStatusMesAnoAtual =
        Table.AddColumn(
            DiasMesAdd,
            "Status Mês Ano Atual",
            each 
                let
                    anoLinha = Date.Year([Data]),
                    mesLinha = Date.Month([Data]),
                    anoAtual = Date.Year(DateTime.LocalNow()),
                    mesAtual = Date.Month(DateTime.LocalNow())
                in
                    if anoLinha <> anoAtual then
                        null
                    else if mesLinha <= mesAtual then
                        "Acumulado"
                    else
                        "Futuro",
            type text
        ),

    // Status dos dias do mês atual
    AddStatusDiaMesAtual =
        Table.AddColumn(
            AddStatusMesAnoAtual,
            "Status Dia Mês Atual",
            each 
                let
                    dataLinha = [Data],
                    hoje      = Date.From(DateTime.LocalNow())
                in
                    if Date.Year(dataLinha) <> Date.Year(hoje)
                       or Date.Month(dataLinha) <> Date.Month(hoje)
                    then
                        null
                    else if dataLinha <= hoje then
                        "Acumulado"
                    else
                        "Futuro",
            type text
        ),

    // -------------------------------------------------------------------------------
    // Campos relativos ao trimestre
    // -------------------------------------------------------------------------------
    TrimAdd =
        Table.AddColumn(
            AddStatusDiaMesAtual,
            "Trimestre",
            each Text.From(Date.QuarterOfYear([Data])) & "ºT",
            type text
        ),

    InicioTrimestre =
        Table.AddColumn(
            TrimAdd,
            "Início do Trimestre",
            each Date.StartOfQuarter([Data]),
            type date
        ),

    FimDoTrimestre =
        Table.AddColumn(
            InicioTrimestre,
            "Fim do Trimestre",
            each Date.EndOfQuarter([Data]),
            type date
        ),

    TrimAnoAdd =
        Table.AddColumn(
            FimDoTrimestre,
            "Ano-Trimestre",
            each Text.Combine({Text.From([Ano]), Text.From([Trimestre], "pt-BR")}, " "),
            type text
        ),

    // Trimestre em inglês
    QuarterEN =
        Table.AddColumn(
            TrimAnoAdd,
            "Quarter",
            each "Q" & Number.ToText(Date.QuarterOfYear([Data])),
            type text
        ),

    YearQuarterEN =
        Table.AddColumn(
            QuarterEN,
            "Year-Quarter",
            each Text.Combine({Text.From([Ano]), [Quarter]}, " "),
            type text
        ),

    // ---------------------------------------------------------------------------------------------------
    // Campos relativos aos semestres
    // ---------------------------------------------------------------------------------------------------
    SemestreAdd =
        Table.AddColumn(
            YearQuarterEN,
            "Semestre",
            each Text.From(if [Mês] > 6 then 2 else 1) & "ºS",
            type text
        ),

    SemestreAnoAdd =
        Table.AddColumn(
            SemestreAdd,
            "Ano-Semestre",
            each Text.Combine({Text.From([Ano], "pt-BR"), [Semestre]}, " "),
            type text
        ),

    // Semestre em inglês
    SemesterEN =
        Table.AddColumn(
            SemestreAnoAdd,
            "Semester",
            each if [Mês] > 6 then "H2" else "H1",
            type text
        ),

    YearSemesterEN =
        Table.AddColumn(
            SemesterEN,
            "Year-Semester",
            each Text.Combine({Text.From([Ano]), [Semester]}, " "),
            type text
        ),

    // --------------------------------------------------------------------------------------------------
    // Campos relativos as semanas
    // --------------------------------------------------------------------------------------------------
    SemAnoAdd =
        Table.AddColumn(
            YearSemesterEN,
            "Semana Ano",
            each Date.WeekOfYear([Data]),
            Int64.Type
        ),

    SemAnoTrat =
        Table.AddColumn(
            SemAnoAdd,
            "Semana do Ano",
            each Text.From(Date.WeekOfYear([Data])) & "ª Sem",
            type text
        ),

    // Semana do Ano EN (curto e longo)
    WeekOfYearEN_Short =
        Table.AddColumn(
            SemAnoTrat,
            "Week of Year (Short)",
            each "W" & Text.From(Date.WeekOfYear([Data])),
            type text
        ),

    WeekOfYearEN_Long =
        Table.AddColumn(
            WeekOfYearEN_Short,
            "Week of Year (Long)",
            each Text.From(Date.WeekOfYear([Data])) & "th Week",
            type text
        ),

    AnoSemanaAdd =
        Table.AddColumn(
            WeekOfYearEN_Long,
            "Ano/Semana",
            each if Text.Length(Text.From([Semana Ano])) < 2
                 then Text.From([Ano]) & "0" & Text.From([Semana Ano])
                 else Text.From([Ano]) & Text.From([Semana Ano]),
            type text
        ),

    // Ano/Semana EN (curto e longo)
    YearWeekEN_Short =
        Table.AddColumn(
            AnoSemanaAdd,
            "Year-Week (Short)",
            each Text.From([Ano]) & "-W" &
                 (if Text.Length(Text.From([Semana Ano])) < 2
                  then "0" & Text.From([Semana Ano])
                  else Text.From([Semana Ano])),
            type text
        ),

    YearWeekEN_Long =
        Table.AddColumn(
            YearWeekEN_Short,
            "Year-Week (Long)",
            each Text.From([Ano]) & " " &
                 Text.From([Semana Ano]) & "th Week",
            type text
        ),

    SemMesAdd =
        Table.AddColumn(
            YearWeekEN_Long,
            "Semana Mês",
            each Date.WeekOfMonth([Data]),
            Int64.Type
        ),

    SemMesTrat =
        Table.AddColumn(
            SemMesAdd,
            "Semana do Mês",
            each Text.From(Date.WeekOfMonth([Data])) & "ª Sem",
            type text
        ),

    // Semana do Mês EN (curto e longo)
    WeekOfMonthEN_Short =
        Table.AddColumn(
            SemMesTrat,
            "Week of Month (Short)",
            each "W" & Text.From(Date.WeekOfMonth([Data])),
            type text
        ),

    WeekOfMonthEN_Long =
        Table.AddColumn(
            WeekOfMonthEN_Short,
            "Week of Month (Long)",
            each Text.From(Date.WeekOfMonth([Data])) & "th Week",
            type text
        ),

    InicioDaSemana =
        Table.AddColumn(
            WeekOfMonthEN_Long,
            "Início da Semana",
            each Date.StartOfWeek([Data]),
            type date
        ),

    FimDaSemana =
        Table.AddColumn(
            InicioDaSemana,
            "Fim da Semana",
            each Date.EndOfWeek([Data]),
            type date
        ),

    // -----------------------------------------------------------------------------------
    // Campos relativos aos dias
    // -----------------------------------------------------------------------------------
    DiaAdd =
        Table.AddColumn(
            FimDaSemana,
            "Dia",
            each Date.Day([Data]),
            Int64.Type
        ),

    DiaAnoAdd =
        Table.AddColumn(
            DiaAdd,
            "Dia do Ano",
            each Date.DayOfYear([Data]),
            Int64.Type
        ),

    DiaSemAdd =
        Table.AddColumn(
            DiaAnoAdd,
            "Dia da Semana",
            each Date.DayOfWeek([Data]),
            Int64.Type
        ),

    NomeDiaAdd =
        Table.AddColumn(
            DiaSemAdd,
            "Nome do Dia",
            each Text.Repeat(Character.FromNumber(8203), 6 - Date.DayOfWeek([Data])) &
                 Date.DayOfWeekName([Data]),
            type text
        ),

    NomeDiaAbrevAdd =
        Table.AddColumn(
            NomeDiaAdd,
            "Nome do Dia.1",
            each Text.Repeat(Character.FromNumber(8203), 6 - Date.DayOfWeek([Data])) &
                 Text.Start(Date.DayOfWeekName([Data]), 3),
            type text
        ),

    InicialDiaAdd =
        Table.AddColumn(
            NomeDiaAbrevAdd,
            "Dia Semana Inicial",
            each Text.Repeat(Character.FromNumber(8203), 6 - Date.DayOfWeek([Data])) &
                 Text.Start(Date.DayOfWeekName([Data]), 1),
            type text
        ),

    // Dia da semana em inglês
    WeekdayEN =
        Table.AddColumn(
            InicialDiaAdd,
            "Weekday",
            each Text.Repeat(Character.FromNumber(8203), 6 - Date.DayOfWeek([Data])) &
                 Date.ToText([Data], "dddd", "en-US"),
            type text
        ),

    WeekdayShortEN =
        Table.AddColumn(
            WeekdayEN,
            "Weekday Short",
            each Text.Repeat(Character.FromNumber(8203), 6 - Date.DayOfWeek([Data])) &
                 Text.Start(Date.ToText([Data], "ddd", "en-US"), 3),
            type text
        ),

    WeekdayInitialEN =
        Table.AddColumn(
            WeekdayShortEN,
            "Weekday Initial",
            each Text.Repeat(Character.FromNumber(8203), 6 - Date.DayOfWeek([Data])) &
                 Text.Start(Date.ToText([Data], "dddd", "en-US"), 1),
            type text
        ),

    // ----------------------------------------------------------------------------------------------------
    // Mescla com os feriados, deduplicados
    // ----------------------------------------------------------------------------------------------------
    FeriadosAdd =
        Table.NestedJoin(
            WeekdayInitialEN,
            {"Data"},
            FeriadosTabelaUnica,
            {"Data"},
            "Feriados_Nacionais",
            JoinKind.LeftOuter
        ),

    Feriados =
        Table.ExpandTableColumn(
            FeriadosAdd,
            "Feriados_Nacionais",
            {"Feriado"},
            {"Feriado"}
        ),

    // ----------------------------------------------------------------------------------------------------
    // Dias úteis em português
    // ----------------------------------------------------------------------------------------------------
    Util =
        Table.AddColumn(
            Feriados,
            "Útil?",
            each
                if [Dia da Semana] = 0 then "Não"
                else if [Dia da Semana] = 6 then "Não"
                else if [Feriado] <> null then "Não"
                else "Sim",
            type text
        ),

    // -----------------------------------------------------------------------------------------------------
    // Ajuste interno
    // -----------------------------------------------------------------------------------------------------
    Rename =
        Table.RenameColumns(
            Util,
            {
                {"Mês", "Nº Mês"},
                {"Nome do Mês", "Mês"},
                {"Dia da Semana", "Nº Dia da Semana"},
                {"Nome do Dia", "Dia da Semana Comp"},
                {"Nome do Dia.1", "Dia da Semana"}
            }
        ),

    Caps =
        Table.TransformColumns(
            Rename,
            {
                {"Dia da Semana Comp", Text.Proper, type text},
                {"Dia da Semana", Text.Proper, type text},
                {"Mês", Text.Proper, type text},
                {"Mês Inicial", Text.Proper, type text},
                {"Dia Semana Inicial", Text.Proper, type text},
                {"Month Full", Text.Proper, type text},
                {"Weekday", Text.Proper, type text}
            }
        ),

    NumMesTextAdd =
        Table.AddColumn(
            Caps,
            "Nº Ano-Mês",
            each Text.From([Ano]) & "/" &
                 (if Text.Length(Text.From([Nº Mês])) = 1
                  then "0" & Text.From([Nº Mês])
                  else Text.From([Nº Mês])),
            type text
        ),

    AnoMesAdd =
        Table.AddColumn(
            NumMesTextAdd,
            "Ano-Mês",
            each Text.Combine({Text.From([Ano], "pt-BR"), [Mês]}, "/"),
            type text
        ),

    Hoje =
        Table.AddColumn(
            AnoMesAdd,
            "Hoje",
            each if [Data] = Date.From(DateTime.LocalNow())
                 then "Hoje"
                 else Text.From([Data]),
            type text
        ),

    EsteAno =
        Table.AddColumn(
            Hoje,
            "Este Ano",
            each if Date.From(DateTime.LocalNow()) >= [Início do Ano]
                    and Date.From(DateTime.LocalNow()) <= [Fim do Ano]
                 then "Este Ano"
                 else Text.From([Ano]),
            type text
        ),

    EsteDia =
        Table.AddColumn(
            EsteAno,
            "Este Dia",
            each if Date.Day([Data]) = Date.Day(DateTime.LocalNow())
                 then "Este Dia"
                 else Text.From([Dia]),
            type text
        ),

    EstaSemana =
        Table.AddColumn(
            EsteDia,
            "Esta Semana",
            each if Date.From(DateTime.LocalNow()) >= [Início da Semana]
                    and Date.From(DateTime.LocalNow()) <= [Fim da Semana]
                 then "Esta Semana"
                 else [Semana do Mês],
            type text
        ),

    EsteMês =
        Table.AddColumn(
            EstaSemana,
            "Este Mês",
            each if Date.Month([Data]) = Date.Month(DateTime.LocalNow())
                 then "Este Mês"
                 else [Mês],
            type text
        ),

    MesAtual =
        Table.AddColumn(
            EsteMês,
            "Mês Atual?",
            each if Date.From(DateTime.LocalNow()) >= [Início do Mês]
                    and Date.From(DateTime.LocalNow()) <= [Fim do Mês]
                 then "Este Mês"
                 else [Mês],
            type text
        ),

    TrimAtual =
        Table.AddColumn(
            MesAtual,
            "Este Trimestre",
            each if Date.From(DateTime.LocalNow()) >= [Início do Trimestre]
                    and Date.From(DateTime.LocalNow()) <= [Fim do Trimestre]
                 then "Este Trimestre"
                 else [Trimestre],
            type text
        ),

    // --------------------------------------------------------------------------------------------------
    // Campos estratégicos em inglês
    // --------------------------------------------------------------------------------------------------
    TodayEN =
        Table.AddColumn(
            TrimAtual,
            "Today",
            each if [Data] = Date.From(DateTime.LocalNow())
                 then "Today"
                 else Date.ToText([Data], "M/d/yyyy", "en-US"),
            type text
        ),

    ThisYearEN =
        Table.AddColumn(
            TodayEN,
            "This Year",
            each if Date.From(DateTime.LocalNow()) >= [Início do Ano]
                    and Date.From(DateTime.LocalNow()) <= [Fim do Ano]
                 then "This Year"
                 else Text.From([Ano]),
            type text
        ),

    ThisDayEN =
        Table.AddColumn(
            ThisYearEN,
            "This Day",
            each if Date.Day([Data]) = Date.Day(DateTime.LocalNow())
                 then "This Day"
                 else Text.From([Dia]),
            type text
        ),

    ThisWeekEN =
        Table.AddColumn(
            ThisDayEN,
            "This Week",
            each if Date.From(DateTime.LocalNow()) >= [Início da Semana]
                    and Date.From(DateTime.LocalNow()) <= [Fim da Semana]
                 then "This Week"
                 else Record.Field(_, "Week of Month (Short)"),
            type text
        ),

    ThisMonthEN =
        Table.AddColumn(
            ThisWeekEN,
            "This Month",
            each if Date.Month([Data]) = Date.Month(DateTime.LocalNow())
                 then "This Month"
                 else [Month Full],
            type text
        ),

    CurrentMonthEN =
        Table.AddColumn(
            ThisMonthEN,
            "Current Month?",
            each if Date.From(DateTime.LocalNow()) >= [Início do Mês]
                    and Date.From(DateTime.LocalNow()) <= [Fim do Mês]
                 then "This Month"
                 else [Month Full],
            type text
        ),

    ThisQuarterEN =
        Table.AddColumn(
            CurrentMonthEN,
            "This Quarter",
            each if Date.From(DateTime.LocalNow()) >= [Início do Trimestre]
                    and Date.From(DateTime.LocalNow()) <= [Fim do Trimestre]
                 then "This Quarter"
                 else [Quarter],
            type text
        ),

    // ---------------------------------------------------------------------------------------------------
    // Dias úteis - interpretação global, descontando somente finais de semana
    // ---------------------------------------------------------------------------------------------------
    WorkdayEN =
        Table.AddColumn(
            ThisQuarterEN,
            "Workday",
            each if Date.DayOfWeek([Data]) = 0 or Date.DayOfWeek([Data]) = 6
                 then "No"
                 else "Yes",
            type text
        ),

    // -----------------------------------------------------------------------------------------------------
    // Estações do ano no contexto meteorológico – hemisfério sul e hemisfério norte
    // -----------------------------------------------------------------------------------------------------

    // Hemisfério Sul em Português
    EstacaoMeteoSulPT =
        Table.AddColumn(
            WorkdayEN,
            "Estação Meteorológica Sul",
            each
                let
                    m = Date.Month([Data])
                in
                    if m = 12 or m = 1 or m = 2 then "Verão"
                    else if m >= 3 and m <= 5 then "Outono"
                    else if m >= 6 and m <= 8 then "Inverno"
                    else "Primavera",
            type text
        ),

    // Hemisfério Sul em Inglês
    EstacaoMeteoSulEN =
        Table.AddColumn(
            EstacaoMeteoSulPT,
            "Meteorological Season South",
            each
                let
                    m = Date.Month([Data])
                in
                    if m = 12 or m = 1 or m = 2 then "Summer"
                    else if m >= 3 and m <= 5 then "Autumn"
                    else if m >= 6 and m <= 8 then "Winter"
                    else "Spring",
            type text
        ),

    // Hemisfério Norte em Português (estações invertidas)
    EstacaoMeteoNortePT =
        Table.AddColumn(
            EstacaoMeteoSulEN,
            "Estação Meteorológica Norte",
            each
                let
                    m = Date.Month([Data])
                in
                    if m = 12 or m = 1 or m = 2 then "Inverno"
                    else if m >= 3 and m <= 5 then "Primavera"
                    else if m >= 6 and m <= 8 then "Verão"
                    else "Outono",
            type text
        ),

    // Hemisfério Norte em Inglês (estações invertidas)
    EstacaoMeteoNorteEN =
        Table.AddColumn(
            EstacaoMeteoNortePT,
            "Meteorological Season North",
            each
                let
                    m = Date.Month([Data])
                in
                    if m = 12 or m = 1 or m = 2 then "Winter"
                    else if m >= 3 and m <= 5 then "Spring"
                    else if m >= 6 and m <= 8 then "Summer"
                    else "Autumn",
            type text
        )
in
    EstacaoMeteoNorteEN
