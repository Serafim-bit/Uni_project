from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

from PIL import Image as PILImage
from PIL import ImageDraw, ImageFont
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "reports"
ASSETS = REPORTS / "_assets"
REPORTS.mkdir(exist_ok=True)
ASSETS.mkdir(exist_ok=True)

PDF_PATH = REPORTS / "sprawozdanie_fit_diary_pl.pdf"
LOGO_PATH = ROOT / "assets" / "branding" / "fit_diary_icon.png"

GREEN = colors.HexColor("#1F7A5C")
DARK_GREEN = colors.HexColor("#073B2F")
MINT = colors.HexColor("#B8F3D5")
INK = colors.HexColor("#17211C")
MUTED = colors.HexColor("#5D6762")
SOFT_BG = colors.HexColor("#F7F9F5")
SOFT_GREEN = colors.HexColor("#E8F5EE")
SOFT_BLUE = colors.HexColor("#EEF5F7")
SOFT_GOLD = colors.HexColor("#FFF6DD")
TABLE_HEAD = colors.HexColor("#F2F4F7")
BORDER = colors.HexColor("#D6E2DD")
WHITE = colors.white


def register_fonts() -> tuple[str, str]:
    candidates = [
        (Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/arialbd.ttf")),
        (Path("C:/Windows/Fonts/calibri.ttf"), Path("C:/Windows/Fonts/calibrib.ttf")),
    ]
    for regular, bold in candidates:
        if regular.exists() and bold.exists():
            pdfmetrics.registerFont(TTFont("FitDiaryRegular", str(regular)))
            pdfmetrics.registerFont(TTFont("FitDiaryBold", str(bold)))
            return "FitDiaryRegular", "FitDiaryBold"
    return "Helvetica", "Helvetica-Bold"


FONT, FONT_BOLD = register_fonts()


def load_json(relative: str):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def count_lines(folder: str) -> int:
    return sum(
        len(path.read_text(encoding="utf-8", errors="ignore").splitlines())
        for path in (ROOT / folder).rglob("*.dart")
    )


def count_files(folder: str, pattern: str = "*") -> int:
    base = ROOT / folder
    if not base.exists():
        return 0
    return len([path for path in base.rglob(pattern) if path.is_file()])


def make_styles():
    base = getSampleStyleSheet()
    return {
        "Hero": ParagraphStyle(
            "Hero",
            parent=base["Title"],
            fontName=FONT_BOLD,
            fontSize=30,
            leading=34,
            textColor=DARK_GREEN,
            alignment=TA_CENTER,
            spaceAfter=8,
        ),
        "HeroSmall": ParagraphStyle(
            "HeroSmall",
            parent=base["Normal"],
            fontName=FONT_BOLD,
            fontSize=13,
            leading=16,
            textColor=GREEN,
            alignment=TA_CENTER,
            spaceAfter=6,
        ),
        "Subtitle": ParagraphStyle(
            "Subtitle",
            parent=base["Normal"],
            fontName=FONT,
            fontSize=11.2,
            leading=15.2,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=16,
        ),
        "H1": ParagraphStyle(
            "H1",
            parent=base["Heading1"],
            fontName=FONT_BOLD,
            fontSize=16.2,
            leading=20,
            textColor=GREEN,
            spaceBefore=15,
            spaceAfter=8,
            keepWithNext=True,
        ),
        "H2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName=FONT_BOLD,
            fontSize=12.8,
            leading=16,
            textColor=DARK_GREEN,
            spaceBefore=10,
            spaceAfter=5,
            keepWithNext=True,
        ),
        "H3": ParagraphStyle(
            "H3",
            parent=base["Heading3"],
            fontName=FONT_BOLD,
            fontSize=10.6,
            leading=13,
            textColor=INK,
            spaceBefore=6,
            spaceAfter=3,
            keepWithNext=True,
        ),
        "Body": ParagraphStyle(
            "Body",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=9.55,
            leading=12.8,
            textColor=INK,
            alignment=TA_LEFT,
            spaceAfter=6,
        ),
        "Lead": ParagraphStyle(
            "Lead",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=10.4,
            leading=14.2,
            textColor=INK,
            alignment=TA_LEFT,
            spaceAfter=8,
        ),
        "Small": ParagraphStyle(
            "Small",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=8.2,
            leading=10.2,
            textColor=MUTED,
            spaceAfter=3,
        ),
        "CardTitle": ParagraphStyle(
            "CardTitle",
            parent=base["BodyText"],
            fontName=FONT_BOLD,
            fontSize=9.4,
            leading=11.8,
            textColor=DARK_GREEN,
            spaceAfter=3,
        ),
        "CardText": ParagraphStyle(
            "CardText",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=8.4,
            leading=10.8,
            textColor=INK,
            spaceAfter=0,
        ),
        "Table": ParagraphStyle(
            "Table",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=8.1,
            leading=10.1,
            textColor=INK,
        ),
        "TableBold": ParagraphStyle(
            "TableBold",
            parent=base["BodyText"],
            fontName=FONT_BOLD,
            fontSize=8.1,
            leading=10.1,
            textColor=INK,
        ),
        "Caption": ParagraphStyle(
            "Caption",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=8.0,
            leading=9.8,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=8,
        ),
    }


STYLES = make_styles()


def p(text: str, style: str = "Body") -> Paragraph:
    return Paragraph(text, STYLES[style])


def bullets(items: list[str]) -> ListFlowable:
    return ListFlowable(
        [ListItem(p(item), leftIndent=6) for item in items],
        bulletType="bullet",
        leftIndent=16,
        bulletFontName=FONT_BOLD,
        bulletFontSize=7,
        bulletOffsetY=1,
    )


def numbers(items: list[str]) -> ListFlowable:
    return ListFlowable(
        [ListItem(p(item), leftIndent=8) for item in items],
        bulletType="1",
        leftIndent=18,
        bulletFontName=FONT_BOLD,
        bulletFontSize=8,
    )


def simple_table(headers: list[str], rows: list[list[object]], widths: list[float]) -> Table:
    data = [[p(str(head), "TableBold") for head in headers]]
    data += [[p(str(cell), "Table") for cell in row] for row in rows]
    table = Table(data, colWidths=[w * cm for w in widths], repeatRows=1, hAlign="CENTER")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), TABLE_HEAD),
                ("GRID", (0, 0), (-1, -1), 0.45, BORDER),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def callout(title: str, body: str, fill=SOFT_GREEN) -> Table:
    table = Table(
        [[p(title, "CardTitle")], [p(body, "CardText")]],
        colWidths=[16.4 * cm],
        hAlign="CENTER",
    )
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), fill),
                ("BOX", (0, 0), (-1, -1), 0.55, BORDER),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return table


def cards(items: list[tuple[str, str]], fill=SOFT_GREEN) -> Table:
    row = []
    for title, body in items:
        row.append([p(title, "CardTitle"), p(body, "CardText")])
    table = Table([row], colWidths=[5.25 * cm] * len(items), hAlign="CENTER")
    style = [
        ("BACKGROUND", (0, 0), (-1, -1), fill),
        ("BOX", (0, 0), (-1, -1), 0.5, BORDER),
        ("INNERGRID", (0, 0), (-1, -1), 6, colors.white),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]
    table.setStyle(TableStyle(style))
    return table


def make_product_map() -> Path:
    out = ASSETS / "product_map_polished.png"
    image = PILImage.new("RGB", (1600, 900), "#F7F9F5")
    draw = ImageDraw.Draw(image)
    try:
        title_font = ImageFont.truetype("arialbd.ttf", 38)
        box_font = ImageFont.truetype("arialbd.ttf", 25)
        small_font = ImageFont.truetype("arial.ttf", 20)
    except Exception:
        title_font = box_font = small_font = None

    def rounded_box(xy, title, lines, fill, outline="#1F7A5C"):
        draw.rounded_rectangle(xy, radius=30, fill=fill, outline=outline, width=4)
        x1, y1, _, _ = xy
        draw.text((x1 + 28, y1 + 22), title, fill="#073B2F", font=box_font)
        y = y1 + 66
        for line in lines:
            draw.text((x1 + 28, y), line, fill="#17211C", font=small_font)
            y += 30

    draw.text((60, 40), "Fit Diary jako produkt: od codziennego zapisu do lepszych nawyków", fill="#073B2F", font=title_font)
    rounded_box((70, 150, 450, 345), "Trening", ["Workout Log", "zdjęcie opcjonalne", "statystyki tygodnia", "edycja i historia"], "#FFFFFF")
    rounded_box((610, 150, 990, 345), "Żywienie", ["Meal Log", "30 przepisów", "filtry i ulubione", "dodanie do dziennika"], "#FFFFFF")
    rounded_box((1150, 150, 1530, 345), "Wiedza", ["Exercise Guide", "20 ćwiczeń", "21 GIF-ów", "kroki techniki"], "#FFFFFF")

    rounded_box((250, 505, 650, 700), "Dane lokalne", ["SQLite + JSON", "bez wymaganego backendu", "działa offline", "łatwe testowanie"], "#E8F5EE")
    rounded_box((940, 505, 1340, 700), "Jakość", ["Material 3", "własna ikona", "24 testy", "analyze bez błędów"], "#E8F5EE")

    for x1, y1, x2, y2 in [(450, 248, 610, 248), (990, 248, 1150, 248), (650, 605, 940, 605)]:
        draw.line((x1, y1, x2, y2), fill="#1F7A5C", width=6)
        draw.polygon([(x2, y2), (x2 - 20, y2 - 11), (x2 - 20, y2 + 11)], fill="#1F7A5C")

    draw.rounded_rectangle((70, 780, 1530, 850), radius=20, fill="#073B2F")
    draw.text((105, 803), "Rezultat: prototyp aplikacji, który można uruchomić na telefonie i rozwijać do MVP.", fill="#FFFFFF", font=box_font)
    image.save(out)
    return out


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont(FONT, 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(1.8 * cm, 1.1 * cm, "Fit Diary | Sprawozdanie projektowe")
    canvas.drawRightString(19.2 * cm, 1.1 * cm, f"Strona {doc.page}")
    canvas.restoreState()


def build_pdf() -> None:
    meals = load_json("assets/data/meals.json")
    categories = load_json("assets/data/categories.json")
    exercises = load_json("assets/data/exercises.json")
    complexity = Counter(meal["complexity"] for meal in meals)
    affordability = Counter(meal["affordability"] for meal in meals)
    exercise_by_muscle = Counter(exercise["muscleGroupId"] for exercise in exercises)

    lib_files = count_files("lib", "*.dart")
    test_files = count_files("test", "*.dart")
    lib_lines = count_lines("lib")
    test_lines = count_lines("test")
    meal_images = count_files("assets/images/meals")
    training_gifs = count_files("assets/images/training_help", "*.gif")
    diagram = make_product_map()

    doc = SimpleDocTemplate(
        str(PDF_PATH),
        pagesize=A4,
        rightMargin=1.55 * cm,
        leftMargin=1.55 * cm,
        topMargin=1.65 * cm,
        bottomMargin=1.75 * cm,
        title="Fit Diary - sprawozdanie",
        author="Codex",
    )

    story = []

    if LOGO_PATH.exists():
        logo = Image(str(LOGO_PATH), width=3.55 * cm, height=3.55 * cm)
        logo.hAlign = "CENTER"
        story += [logo, Spacer(1, 0.28 * cm)]

    story += [
        p("Fit Diary", "Hero"),
        p("Sprawozdanie z projektu aplikacji mobilnej", "HeroSmall"),
        p("Osobisty dziennik fitness łączący trening, żywienie, przepisy, przewodnik ćwiczeń i notatki w jednym spójnym prototypie Flutter.", "Subtitle"),
        Spacer(1, 0.2 * cm),
        cards(
            [
                ("Cel produktu", "Pomóc użytkownikowi szybciej zapisać trening, posiłek lub notatkę bez rozpraszania i bez konta online."),
                ("Status", "Działający prototyp uruchamiany na telefonie, z lokalnym zapisem danych i testami automatycznymi."),
                ("Największa wartość", "Jedno lekkie miejsce na codzienny fitness: dziennik, wiedza, przepisy i historia aktywności."),
            ],
            fill=SOFT_GREEN,
        ),
        Spacer(1, 0.45 * cm),
        simple_table(
            ["Informacja", "Wartość"],
            [
                ["Nazwa projektu", "Fit Diary / uni_project"],
                ["Typ aplikacji", "Personal fitness diary / offline-first mobile prototype"],
                ["Technologie", "Flutter, Dart, Material 3, SQLite, JSON assets"],
                ["Data raportu", "12 czerwca 2026"],
                ["Weryfikacja", "flutter analyze: bez błędów; flutter test: 24/24 testy zaliczone"],
            ],
            [4.0, 12.2],
        ),
        Spacer(1, 0.45 * cm),
        callout(
            "Krótka ocena",
            "Projekt nie jest tylko zestawem ekranów demonstracyjnych. Ma realny przepływ użytkownika, lokalne bazy danych, media offline, własny branding, testy oraz spójną strukturę modułów. Najlepiej opisywać go jako działający prototyp produktu, który może zostać rozwinięty do MVP.",
            fill=SOFT_GOLD,
        ),
        PageBreak(),
    ]

    story += [
        p("Spis treści", "H1"),
        bullets(
            [
                "1. Koncepcja produktu i problem użytkownika",
                "2. Najważniejsze funkcje aplikacji",
                "3. Doświadczenie użytkownika i warstwa wizualna",
                "4. Architektura techniczna",
                "5. Dane, persistencja i zasoby lokalne",
                "6. Jakość, testy i uruchomienie",
                "7. Ograniczenia i ryzyka",
                "8. Plan rozwoju do MVP",
                "9. Wnioski końcowe",
                "Załączniki techniczne",
            ]
        ),
        PageBreak(),
    ]

    story += [
        p("1. Koncepcja produktu i problem użytkownika", "H1"),
        p("Fit Diary powstał jako odpowiedź na prosty problem: osoba trenująca często potrzebuje zapisać kilka różnych informacji, ale robi to w wielu miejscach naraz. Trening trafia do notatnika, posiłki do oddzielnej aplikacji, technika ćwiczeń do wyszukiwarki, a drobne przypomnienia do listy zadań. Efekt jest taki, że dane są rozproszone i po kilku dniach trudno do nich wrócić."),
        p("Aplikacja proponuje jedno spokojne, uporządkowane miejsce na codzienne wpisy fitness. Użytkownik nie musi zakładać konta, konfigurować planu ani korzystać z internetu. Po otwarciu aplikacji widzi najważniejsze akcje, ostatni trening i może szybko przejść do zapisu aktywności, żywienia, przepisów, ćwiczeń lub notatek."),
        p("1.1. Grupa docelowa", "H2"),
        bullets(
            [
                "osoby początkujące i średnio zaawansowane, które chcą prowadzić prosty dziennik aktywności;",
                "użytkownicy trenujący nieregularnie, dla których ważniejsza jest łatwość zapisu niż rozbudowane plany treningowe;",
                "studenci lub osoby aktywne, które chcą mieć notatki, posiłki i trening w jednym miejscu;",
                "użytkownicy preferujący lokalne dane zamiast konta online i synchronizacji w chmurze.",
            ]
        ),
        p("1.2. Propozycja wartości", "H2"),
        cards(
            [
                ("Szybkość", "Najważniejsze moduły są dostępne z ekranu głównego, a formularze działają bez długiej konfiguracji."),
                ("Praktyczność", "Aplikacja pozwala zapisać trening nawet bez zdjęcia i dodać przepis do dziennika posiłków jednym przepływem."),
                ("Spójność", "Trening, żywienie, ćwiczenia i notatki są połączone jedną estetyką i lokalnym modelem danych."),
            ],
            fill=SOFT_BLUE,
        ),
    ]

    story += [
        p("2. Najważniejsze funkcje aplikacji", "H1"),
        p("Zakres funkcjonalny został dobrany tak, aby prototyp przypominał prawdziwy produkt, a nie pojedynczą demonstrację techniczną. Użytkownik może rozpocząć od ekranu głównego, przejść do najważniejszego modułu Workout Log, uzupełnić dziennik żywienia, sprawdzić technikę ćwiczenia albo zapisać krótką notatkę."),
        simple_table(
            ["Moduł", "Co daje użytkownikowi", "Stan"],
            [
                ["Home", "Szybki start, data, ostatni trening i cztery główne akcje.", "Gotowe"],
                ["Workout Log", "Historia treningów, edycja, usuwanie, filtry, sortowanie, statystyki i opcjonalne zdjęcie.", "Najważniejszy moduł"],
                ["Nutrition", "Dziennik posiłków z kaloriami, białkiem i notatkami.", "Gotowe"],
                ["Recipes", "30 przepisów, wyszukiwanie, filtry, ulubione i dodanie przepisu do Meal Log.", "Gotowe"],
                ["Exercise Guide", "20 ćwiczeń z GIF-ami oraz krokami techniki.", "Gotowe"],
                ["Notes", "Prosty lokalny CRUD dla drobnych notatek i zadań.", "Gotowe"],
            ],
            [3.1, 10.4, 2.7],
        ),
        p("2.1. Dlaczego te funkcje są spójne", "H2"),
        p("Najważniejsza decyzja produktowa polega na tym, że aplikacja nie próbuje być jednocześnie trenerem AI, serwisem społecznościowym i planerem dietetycznym. Zamiast tego skupia się na codziennym zapisie i szybkim dostępie do informacji. Dzięki temu prototyp jest zrozumiały, łatwy do pokazania i realistyczny do dalszego rozwijania."),
        p("2.2. Przykładowy dzień użytkownika", "H2"),
        numbers(
            [
                "Użytkownik otwiera aplikację i widzi kartę ostatniego treningu.",
                "Po treningu dodaje raport: data, fokus, czas, ćwiczenia i ewentualnie zdjęcie.",
                "W module Nutrition zapisuje posiłek albo wybiera przepis z katalogu.",
                "Jeżeli nie pamięta techniki, otwiera Exercise Guide i sprawdza GIF oraz kroki wykonania.",
                "Na koniec zapisuje krótką notatkę, np. przypomnienie o rozciąganiu lub zakupach.",
            ]
        ),
    ]

    story += [
        p("3. Doświadczenie użytkownika i warstwa wizualna", "H1"),
        p("Interfejs został przebudowany w kierunku spokojnego, jednolitego stylu Material 3. Dominują jasne tła, zielony akcent marki, czytelne karty i mocna hierarchia nagłówków. Aplikacja nie wygląda jak surowy projekt z domyślnym motywem Fluttera, ponieważ ma własną ikonę, własne obrazy, spójne komponenty i konsekwentną paletę."),
        cards(
            [
                ("Czysty ekran startowy", "Usunięto nadmiarowy blok Explore training, dzięki czemu Home jest bardziej skupiony i nie wymaga zbędnego przewijania."),
                ("Lepsze formularze", "Workout Log i Nutrition używają bottom sheetów oraz jasnych pól, dzięki czemu zapis danych jest naturalny na telefonie."),
                ("Branding", "Aplikacja ma własne logo zamiast standardowej ikony Fluttera, co wzmacnia wrażenie gotowego produktu."),
            ],
            fill=SOFT_GREEN,
        ),
        p("3.1. Motyw aplikacji", "H2"),
        simple_table(
            ["Element", "Opis"],
            [
                ["Kolor przewodni", "#1F7A5C, używany jako seed color w Material 3."],
                ["Tło", "#F7F9F5, jasne i spokojne, pasujące do aplikacji zdrowotnej."],
                ["Karty", "Białe powierzchnie, brak ciężkich cieni, zaokrąglenia i czytelna typografia."],
                ["Przyciski", "Spójne FilledButton, ElevatedButton, OutlinedButton i FloatingActionButton."],
                ["Media", "Lokalne zdjęcia jedzenia i GIF-y ćwiczeń zamiast pustych placeholderów."],
            ],
            [4.2, 12.0],
        ),
    ]

    story += [
        p("4. Architektura techniczna", "H1"),
        p("Projekt ma prostą, ale rozsądną architekturę dla prototypu Flutter. Kod jest podzielony według obszarów funkcjonalnych: start, trainings, train_help, meals i notes. Każdy ważny obszar ma własne modele, ekrany i usługi danych. Punkt wejścia znajduje się w lib/main.dart, gdzie MaterialApp ładuje motyw oraz StartScreen."),
        Image(str(diagram), width=16.5 * cm, height=9.3 * cm),
        p("Rysunek 1. Produktowa mapa modułów Fit Diary.", "Caption"),
        p("4.1. Warstwy projektu", "H2"),
        simple_table(
            ["Warstwa", "Odpowiedzialność", "Przykłady"],
            [
                ["UI", "Ekrany, karty, formularze, listy i nawigacja.", "StartScreen, TrainingLogScreen, NutritionScreen"],
                ["Modele", "Reprezentacja danych w Dart.", "TrainingReport, MealEntry, Meal, Task, Exercise"],
                ["Usługi danych", "SQLite i wczytywanie JSON.", "TrainingDatabaseService, MealLogDatabaseService, DataService"],
                ["Zasoby", "Zdjęcia, GIF-y, JSON, ikony aplikacji.", "assets/data, assets/images, assets/branding"],
                ["Testy", "Weryfikacja logiki i przepływów.", "database_services_test, recipes_widget_test"],
            ],
            [3.0, 7.1, 6.1],
        ),
        p("4.2. Dlaczego architektura jest wystarczająca", "H2"),
        p("Dla obecnego etapu projektu nie ma potrzeby dodawania ciężkiego stanu globalnego, backendu ani skomplikowanej architektury enterprise. Dane są lokalne, ekrany są jasno rozdzielone, a serwisy SQLite izolują operacje zapisu i odczytu. To pozwala szybko rozwijać prototyp bez nadmiarowego skomplikowania."),
    ]

    story += [
        p("5. Dane, persistencja i zasoby lokalne", "H1"),
        p("Fit Diary działa w modelu offline-first. Oznacza to, że najważniejsze dane użytkownika nie wymagają konta ani sieci. Treningi, posiłki, ulubione przepisy i notatki są zapisywane lokalnie w SQLite, a przepisy i ćwiczenia są dostarczone jako pliki JSON oraz assets."),
        simple_table(
            ["Baza / plik", "Zawartość", "Znaczenie produktowe"],
            [
                ["training_reports.db", "Tabela training_reports z datą, fokusem, czasem, ćwiczeniami i zdjęciem.", "Historia aktywności użytkownika."],
                ["meal_log.db", "meal_entries oraz favorite_recipes.", "Dziennik żywienia i zapamiętywanie przepisów."],
                ["tasks.db", "Tabela tasks.", "Szybkie notatki i przypomnienia."],
                ["meals.json", f"{len(meals)} przepisów.", "Gotowy katalog żywieniowy bez internetu."],
                ["exercises.json", f"{len(exercises)} ćwiczeń.", "Przewodnik techniki ćwiczeń."],
            ],
            [3.7, 6.2, 6.3],
        ),
        p("5.1. Skala katalogu", "H2"),
        cards(
            [
                ("Przepisy", f"{len(meals)} pozycji, {len(categories)} kategorii, {meal_images} lokalnych zdjęć."),
                ("Ćwiczenia", f"{len(exercises)} pozycji, {training_gifs} lokalnych GIF-ów, grupy: {', '.join(sorted(exercise_by_muscle.keys()))}."),
                ("Kod i testy", f"{lib_files} pliki Dart w lib, {test_files} plików testowych, 24 testy automatyczne."),
            ],
            fill=SOFT_BLUE,
        ),
        p("5.2. Jakość danych", "H2"),
        p(f"Katalog przepisów jest praktyczny, ponieważ większość pozycji jest prosta i codzienna: {complexity.get('simple', 0)} przepisów ma poziom simple, {complexity.get('challenging', 0)} challenging, a {complexity.get('hard', 0)} hard. Również koszt jest przyjazny: {affordability.get('affordable', 0)} przepisów oznaczono jako affordable."),
    ]

    story += [
        p("6. Jakość, testy i uruchomienie", "H1"),
        p("Projekt został sprawdzony automatycznie. Analiza statyczna nie zgłasza błędów, a pełny zestaw testów przechodzi poprawnie. To istotne, ponieważ aplikacja posiada kilka lokalnych baz danych i przepływów formularzy, które łatwo uszkodzić przy dalszym rozwoju."),
        simple_table(
            ["Sprawdzenie", "Wynik"],
            [
                ["flutter analyze", "No issues found"],
                ["flutter test --reporter expanded --no-pub", "24 testy zaliczone, 0 błędów"],
                ["Testy baz danych", "CRUD, migracje, ulubione przepisy, usuwanie zdjęć treningowych."],
                ["Testy widgetowe", "Home, Nutrition, Recipes, Notes, Exercise Guide, Workout Log."],
                ["Testy katalogów", "Poprawność JSON oraz istnienie lokalnych obrazów i GIF-ów."],
            ],
            [5.8, 10.4],
        ),
        p("6.1. Uruchomienie projektu", "H2"),
        simple_table(
            ["Cel", "Komenda"],
            [
                ["Pobranie zależności", "flutter pub get"],
                ["Start aplikacji", "flutter run"],
                ["Start na telefonie", "flutter run -d 9f1145f4"],
                ["Profilowanie wydajności", "flutter run --profile -d 9f1145f4"],
                ["Testy", "flutter test"],
                ["Debug APK", "flutter build apk --debug"],
            ],
            [5.0, 11.2],
        ),
    ]

    story += [
        p("7. Ograniczenia i ryzyka", "H1"),
        p("Obecna wersja jest bardzo dobrym prototypem, ale nie powinna być przedstawiana jako gotowa aplikacja sklepowa. Najważniejsze braki dotyczą nie podstawowego działania, lecz opakowania produkcyjnego, zarządzania danymi użytkownika i długoterminowej skalowalności."),
        bullets(
            [
                "brak kont użytkowników, backendu i synchronizacji między urządzeniami;",
                "brak eksportu/importu danych treningowych i żywieniowych;",
                "brak podpisanej konfiguracji release oraz finalnego package id;",
                "brak formalnej polityki prywatności i procesu usuwania danych;",
                "statyczny katalog ćwiczeń i przepisów, bez edycji przez użytkownika;",
                "część ekranów jest duża i w przyszłości warto rozbić je na mniejsze widgety oraz kontrolery logiki.",
            ]
        ),
        callout(
            "Interpretacja ryzyka",
            "Te ograniczenia nie przekreślają projektu. Są typowe dla etapu prototypu. Najważniejsze jest to, że główne przepływy działają, dane są zapisywane lokalnie, a aplikacja ma wystarczająco solidną bazę do dalszego rozwoju.",
            fill=SOFT_GOLD,
        ),
    ]

    story += [
        p("8. Plan rozwoju do MVP", "H1"),
        p("Dalszy rozwój powinien wzmacniać to, co jest już rdzeniem aplikacji: Workout Log i Nutrition. Zamiast dodawać wiele nowych modułów, lepiej dopracować zapisywanie, statystyki, eksport danych i jakość doświadczenia na telefonie."),
        simple_table(
            ["Priorytet", "Zadanie", "Wartość"],
            [
                ["P1", "Eksport i backup danych lokalnych.", "Chroni historię użytkownika i zwiększa zaufanie."],
                ["P1", "Wykresy aktywności i trendów treningowych.", "Nadaje sens długoterminowemu prowadzeniu dziennika."],
                ["P1", "Ekran szczegółów przepisu i możliwość dodania własnego przepisu.", "Rozwija drugi najważniejszy obszar produktu."],
                ["P2", "Lepsza lokalizacja PL/EN.", "Ułatwia prezentację i realne użycie."],
                ["P2", "Refaktoryzacja dużych ekranów.", "Ułatwia utrzymanie i dalszy rozwój."],
                ["P3", "Backend i synchronizacja.", "Opcjonalny krok po ustabilizowaniu MVP."],
                ["P3", "Release pipeline: podpis, package id, polityka prywatności.", "Konieczne przed publikacją w sklepie."],
            ],
            [2.0, 7.5, 6.7],
        ),
    ]

    story += [
        p("9. Wnioski końcowe", "H1"),
        p("Fit Diary można przedstawić jako działający, przemyślany prototyp aplikacji mobilnej. Projekt ma jasny problem użytkownika, logiczny zakres funkcji, lokalną bazę danych, katalog mediów, spójną estetykę i testy automatyczne. Najważniejsze moduły nie są atrapami: można dodać trening, edytować go, zapisać posiłek, dodać przepis do dziennika, otworzyć przewodnik ćwiczeń i prowadzić notatki."),
        p("Najmocniejszą stroną projektu jest połączenie praktyczności z prostotą. Aplikacja nie wymaga konta, nie udaje rozbudowanej platformy sportowej i nie przeciąża użytkownika. Jest małym osobistym panelem fitness, który może zostać rozwinięty do MVP przez dodanie eksportu danych, wykresów i dopracowania release."),
        callout(
            "Finalna ocena projektu",
            "Projekt jest kompletny na poziomie prototypu i nadaje się do pokazania jako aplikacja działająca na realnym telefonie. W sprawozdaniu warto podkreślić nie tylko technologię, ale też wartość użytkową: Fit Diary porządkuje codzienne informacje fitness w jednym miejscu.",
            fill=SOFT_GREEN,
        ),
    ]

    story += [
        p("Załącznik A. Metryki techniczne", "H1"),
        simple_table(
            ["Metryka", "Wartość"],
            [
                ["Pliki Dart w lib", lib_files],
                ["Linie kodu Dart w lib", lib_lines],
                ["Pliki testowe", test_files],
                ["Linie testów", test_lines],
                ["Testy automatyczne", "24 zaliczone"],
                ["Przepisy", len(meals)],
                ["Kategorie przepisów", len(categories)],
                ["Ćwiczenia", len(exercises)],
                ["Lokalne zdjęcia posiłków", meal_images],
                ["Lokalne GIF-y treningowe", training_gifs],
            ],
            [7.8, 8.4],
        ),
        p("Załącznik B. Źródła informacji", "H1"),
        bullets(
            [
                "README.md - opis projektu, funkcji, struktury i testów;",
                "pubspec.yaml - zależności, wersja i konfiguracja assets;",
                "lib/ - implementacja aplikacji Flutter;",
                "assets/data/*.json - dane przepisów, kategorii i ćwiczeń;",
                "assets/ATTRIBUTIONS.md - źródła i licencje mediów;",
                "test/*.dart - testy automatyczne;",
                "wyniki lokalnych komend: flutter analyze oraz flutter test --reporter expanded --no-pub.",
            ]
        ),
    ]

    doc.build(story, onFirstPage=footer, onLaterPages=footer)


if __name__ == "__main__":
    build_pdf()
    print(PDF_PATH)
