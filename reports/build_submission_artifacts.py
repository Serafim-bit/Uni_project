from __future__ import annotations

import json
import os
import zipfile
from collections import Counter
from datetime import date
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
ZIP_PATH = REPORTS / "Fit_Diary_pliki_zrodlowe.zip"
LOGO_PATH = ROOT / "assets" / "branding" / "fit_diary_icon.png"

GREEN = colors.HexColor("#1F7A5C")
DARK_GREEN = colors.HexColor("#073B2F")
INK = colors.HexColor("#17211C")
MUTED = colors.HexColor("#5D6762")
LIGHT_BG = colors.HexColor("#F7F9F5")
LIGHT_GREEN = colors.HexColor("#E9F5EF")
TABLE_HEAD = colors.HexColor("#F2F4F7")
BORDER = colors.HexColor("#D9E2DD")


def register_fonts() -> tuple[str, str]:
    candidates = [
        (Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/arialbd.ttf")),
        (
            Path("C:/Windows/Fonts/calibri.ttf"),
            Path("C:/Windows/Fonts/calibrib.ttf"),
        ),
        (
            Path("C:/Users/seraf/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/Lib/site-packages/reportlab/fonts/Vera.ttf"),
            Path("C:/Users/seraf/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/Lib/site-packages/reportlab/fonts/VeraBd.ttf"),
        ),
    ]
    for regular, bold in candidates:
        if regular.exists() and bold.exists():
            pdfmetrics.registerFont(TTFont("ReportRegular", str(regular)))
            pdfmetrics.registerFont(TTFont("ReportBold", str(bold)))
            return "ReportRegular", "ReportBold"
    return "Helvetica", "Helvetica-Bold"


FONT_REGULAR, FONT_BOLD = register_fonts()


def load_json(path: str):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def count_lines(folder: str) -> int:
    root = ROOT / folder
    return sum(
        len(path.read_text(encoding="utf-8", errors="ignore").splitlines())
        for path in root.rglob("*.dart")
    )


def count_files(folder: str, pattern: str = "*") -> int:
    path = ROOT / folder
    return len([p for p in path.rglob(pattern) if p.is_file()])


def make_styles():
    base = getSampleStyleSheet()
    styles = {
        "Title": ParagraphStyle(
            "Title",
            parent=base["Title"],
            fontName=FONT_BOLD,
            fontSize=28,
            leading=32,
            textColor=DARK_GREEN,
            alignment=TA_CENTER,
            spaceAfter=10,
        ),
        "Subtitle": ParagraphStyle(
            "Subtitle",
            parent=base["Normal"],
            fontName=FONT_REGULAR,
            fontSize=12,
            leading=16,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=18,
        ),
        "H1": ParagraphStyle(
            "H1",
            parent=base["Heading1"],
            fontName=FONT_BOLD,
            fontSize=16,
            leading=20,
            textColor=GREEN,
            spaceBefore=14,
            spaceAfter=8,
        ),
        "H2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName=FONT_BOLD,
            fontSize=13,
            leading=16,
            textColor=DARK_GREEN,
            spaceBefore=10,
            spaceAfter=6,
        ),
        "H3": ParagraphStyle(
            "H3",
            parent=base["Heading3"],
            fontName=FONT_BOLD,
            fontSize=11,
            leading=14,
            textColor=INK,
            spaceBefore=8,
            spaceAfter=4,
        ),
        "Body": ParagraphStyle(
            "Body",
            parent=base["BodyText"],
            fontName=FONT_REGULAR,
            fontSize=9.7,
            leading=13.0,
            textColor=INK,
            alignment=TA_LEFT,
            spaceAfter=6,
        ),
        "Small": ParagraphStyle(
            "Small",
            parent=base["BodyText"],
            fontName=FONT_REGULAR,
            fontSize=8.4,
            leading=10.6,
            textColor=INK,
            spaceAfter=3,
        ),
        "Table": ParagraphStyle(
            "Table",
            parent=base["BodyText"],
            fontName=FONT_REGULAR,
            fontSize=8.2,
            leading=10.2,
            textColor=INK,
        ),
        "TableBold": ParagraphStyle(
            "TableBold",
            parent=base["BodyText"],
            fontName=FONT_BOLD,
            fontSize=8.2,
            leading=10.2,
            textColor=INK,
        ),
        "Caption": ParagraphStyle(
            "Caption",
            parent=base["BodyText"],
            fontName=FONT_REGULAR,
            fontSize=8.2,
            leading=10,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=8,
        ),
        "CalloutTitle": ParagraphStyle(
            "CalloutTitle",
            parent=base["BodyText"],
            fontName=FONT_BOLD,
            fontSize=9.5,
            leading=12,
            textColor=DARK_GREEN,
            spaceAfter=4,
        ),
    }
    return styles


STYLES = make_styles()


def p(text: str, style: str = "Body") -> Paragraph:
    return Paragraph(text, STYLES[style])


def bullets(items: list[str]) -> ListFlowable:
    return ListFlowable(
        [ListItem(p(item), leftIndent=8) for item in items],
        bulletType="bullet",
        start="circle",
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


def table(headers: list[str], rows: list[list[object]], widths: list[float]) -> Table:
    data = [[p(str(h), "TableBold") for h in headers]]
    for row in rows:
        data.append([p(str(cell), "Table") for cell in row])
    t = Table(data, colWidths=[w * cm for w in widths], repeatRows=1, hAlign="CENTER")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), TABLE_HEAD),
                ("TEXTCOLOR", (0, 0), (-1, 0), INK),
                ("GRID", (0, 0), (-1, -1), 0.45, BORDER),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return t


def callout(title: str, body: str) -> Table:
    data = [[p(title, "CalloutTitle")], [p(body, "Body")]]
    t = Table(data, colWidths=[16.2 * cm], hAlign="CENTER")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), LIGHT_GREEN),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#B7D8C8")),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )
    return t


def make_architecture_diagram() -> Path:
    path = ASSETS / "architecture_diagram.png"
    img = PILImage.new("RGB", (1500, 860), "#F7F9F5")
    draw = ImageDraw.Draw(img)
    try:
        font_big = ImageFont.truetype("arial.ttf", 36)
        font = ImageFont.truetype("arial.ttf", 25)
        font_small = ImageFont.truetype("arial.ttf", 20)
    except Exception:
        font_big = font = font_small = None

    def box(xy, title, lines, fill):
        outline = "#1F7A5C"
        draw.rounded_rectangle(xy, radius=28, fill=fill, outline=outline, width=3)
        x1, y1, _x2, _y2 = xy
        draw.text((x1 + 24, y1 + 18), title, fill="#073B2F", font=font)
        y = y1 + 60
        for line in lines:
            draw.text((x1 + 24, y), line, fill="#17211C", font=font_small)
            y += 30

    draw.text((45, 32), "Architektura logiczna aplikacji Fit Diary", fill="#073B2F", font=font_big)
    box((65, 118, 455, 300), "Warstwa UI", ["StartScreen", "Workout Log", "Nutrition", "Exercise Guide", "Notes"], "#FFFFFF")
    box((555, 118, 945, 300), "Modele i logika", ["TrainingReport", "MealEntry / Meal", "Task", "Exercise / Category"], "#FFFFFF")
    box((1035, 118, 1435, 300), "Dane lokalne", ["SQLite: 3 bazy", "JSON: przepisy i cwiczenia", "Assets: zdjecia i GIF"], "#FFFFFF")
    box((135, 430, 525, 625), "Offline-first", ["Dane zapisywane lokalnie", "Brak wymaganego backendu", "Szybki dostep do katalogow"], "#E9F5EF")
    box((585, 430, 975, 625), "Material 3", ["Jednolity motyw", "Zielona paleta Fit Diary", "Karty, bottom sheets, chips"], "#E9F5EF")
    box((1035, 430, 1375, 625), "Testy", ["24 testy", "CRUD i migracje", "Scenariusze widgetowe"], "#E9F5EF")

    for x1, y1, x2, y2 in [(455, 210, 555, 210), (945, 210, 1035, 210), (525, 528, 585, 528), (975, 528, 1035, 528)]:
        draw.line((x1, y1, x2, y2), fill="#1F7A5C", width=5)
        draw.polygon([(x2, y2), (x2 - 18, y2 - 10), (x2 - 18, y2 + 10)], fill="#1F7A5C")

    draw.rounded_rectangle((65, 710, 1435, 785), radius=20, fill="#073B2F")
    draw.text((100, 733), "Przeplyw: ekran -> model formularza -> serwis SQLite/JSON -> odswiezenie stanu UI", fill="#FFFFFF", font=font)
    img.save(path)
    return path


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont(FONT_REGULAR, 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(2 * cm, 1.15 * cm, "Fit Diary | Sprawozdanie techniczne projektu")
    canvas.drawRightString(19 * cm, 1.15 * cm, f"Strona {doc.page}")
    canvas.restoreState()


def build_pdf() -> None:
    meals = load_json("assets/data/meals.json")
    categories = load_json("assets/data/categories.json")
    exercises = load_json("assets/data/exercises.json")

    meal_by_cat = Counter(cat for meal in meals for cat in meal["categories"])
    exercise_by_muscle = Counter(e["muscleGroupId"] for e in exercises)
    complexity = Counter(m["complexity"] for m in meals)
    affordability = Counter(m["affordability"] for m in meals)

    lib_files = count_files("lib", "*.dart")
    test_files = count_files("test", "*.dart")
    lib_lines = count_lines("lib")
    test_lines = count_lines("test")
    meal_images = count_files("assets/images/meals")
    training_gifs = count_files("assets/images/training_help", "*.gif")
    diagram = make_architecture_diagram()

    doc = SimpleDocTemplate(
        str(PDF_PATH),
        pagesize=A4,
        rightMargin=1.65 * cm,
        leftMargin=1.65 * cm,
        topMargin=1.75 * cm,
        bottomMargin=1.8 * cm,
        title="Sprawozdanie Fit Diary",
        author="Codex",
    )

    story: list = []

    if LOGO_PATH.exists():
        story.append(Image(str(LOGO_PATH), width=3.4 * cm, height=3.4 * cm))
        story[-1].hAlign = "CENTER"
        story.append(Spacer(1, 0.35 * cm))

    story.extend(
        [
            p("SPRAWOZDANIE Z PROJEKTU", "Title"),
            p("Fit Diary", "Title"),
            p("Aplikacja Flutter do prowadzenia dziennika treningów, posiłków, przepisów i notatek", "Subtitle"),
            Spacer(1, 0.2 * cm),
            table(
                ["Pole", "Wartość"],
                [
                    ["Nazwa projektu", "Fit Diary / uni_project"],
                    ["Technologia", "Flutter, Dart, Material 3, SQLite, lokalne zasoby JSON i media"],
                    ["Typ opracowania", "Sprawozdanie techniczne i produktowe"],
                    ["Data opracowania", "12 czerwca 2026"],
                    ["Status", "Działający prototyp aplikacji mobilnej, przetestowany automatycznie"],
                ],
                [4.2, 11.8],
            ),
            Spacer(1, 0.45 * cm),
            callout(
                "Teza sprawozdania",
                "Fit Diary jest kompletnym prototypem aplikacji typu offline-first. Projekt ma czytelny podział na moduły, lokalną persistencję danych, katalog przepisów i ćwiczeń, spójny interfejs Material 3 oraz zestaw testów potwierdzających kluczowe przepływy użytkownika.",
            ),
            PageBreak(),
        ]
    )

    story.append(p("Spis treści", "H1"))
    story.append(
        bullets(
            [
                "1. Streszczenie i cel projektu",
                "2. Zakres funkcjonalny aplikacji",
                "3. Technologie, zależności i konfiguracja",
                "4. Architektura projektu",
                "5. Moduły aplikacji",
                "6. Dane, baza SQLite i zasoby lokalne",
                "7. Interfejs użytkownika i doświadczenie użytkownika",
                "8. Testowanie i jakość",
                "9. Wydajność, bezpieczeństwo i ograniczenia",
                "10. Plan dalszego rozwoju",
                "11. Instrukcja uruchomienia",
                "12. Wnioski końcowe",
                "Załączniki",
            ]
        )
    )
    story.append(PageBreak())

    story += [
        p("1. Streszczenie i cel projektu", "H1"),
        p("Fit Diary to prototyp aplikacji mobilnej napisanej we Flutterze, której głównym celem jest połączenie kilku codziennych narzędzi związanych z aktywnością fizyczną w jednym, prostym środowisku. Aplikacja umożliwia zapisywanie treningów, przeglądanie ćwiczeń z demonstracjami GIF, prowadzenie dziennika posiłków, korzystanie z katalogu przepisów oraz tworzenie krótkich notatek."),
        p("Projekt ma charakter praktyczny: najważniejszym założeniem nie jest skomplikowana architektura serwerowa, lecz szybka praca na urządzeniu, przejrzysty interfejs oraz możliwość korzystania z danych lokalnie. Z tego powodu aplikacja wykorzystuje SQLite przez pakiet sqflite, dane katalogowe w plikach JSON oraz obrazy zapisane w katalogu assets."),
        p("W obecnym stanie projekt można traktować jako solidny prototyp produktu. Obejmuje on najważniejsze ścieżki użytkownika, ma spójny język wizualny, własną ikonę aplikacji, lokalne media oraz testy automatyczne sprawdzające modele, bazy danych i przepływy ekranowe."),
        p("1.1. Główne cele", "H2"),
        bullets(
            [
                "utworzenie aplikacji fitness działającej bez wymaganego backendu;",
                "zapewnienie zapisu lokalnego dla treningów, posiłków, ulubionych przepisów i notatek;",
                "zaprojektowanie czytelnego ekranu startowego z szybkim dostępem do funkcji;",
                "przygotowanie katalogu ćwiczeń i przepisów z lokalnymi obrazami;",
                "utrzymanie spójnego wyglądu aplikacji poprzez wspólny motyw Material 3;",
                "potwierdzenie działania projektu testami jednostkowymi, bazodanowymi i widgetowymi.",
            ]
        ),
        p("1.2. Charakter projektu", "H2"),
        p("Projekt nie jest jeszcze finalnym produktem komercyjnym gotowym do publikacji w sklepie aplikacji, ponieważ brakuje mu m.in. podpisania release, pełnej polityki prywatności, eksportu danych oraz mechanizmów synchronizacji. Jest natomiast działającym prototypem, który można uruchamiać na telefonie, prezentować użytkownikom i rozwijać w stronę wersji MVP."),
    ]

    story += [
        p("2. Zakres funkcjonalny aplikacji", "H1"),
        p("Aplikacja składa się z pięciu głównych obszarów: ekranu startowego, dziennika treningów, przewodnika po ćwiczeniach, modułu żywienia oraz notatek. Każdy z nich odpowiada za odrębną część doświadczenia użytkownika, ale całość pozostaje połączona wspólnym motywem i wspólną strukturą nawigacji."),
        table(
            ["Obszar", "Opis funkcji", "Stan"],
            [
                ["Home dashboard", "Ekran główny z datą, kartą ostatniego treningu i szybkimi akcjami.", "Gotowe"],
                ["Workout Log", "Dodawanie, edycja, usuwanie, sortowanie i filtrowanie treningów; zdjęcie opcjonalne; statystyki.", "Gotowe jako prototyp"],
                ["Nutrition", "Dziennik posiłków, statystyka kalorii/białka, edycja wpisów.", "Gotowe jako prototyp"],
                ["Recipes", "Katalog 30 przepisów, wyszukiwanie, filtry, ulubione i dodawanie przepisu do Meal Log.", "Gotowe jako prototyp"],
                ["Exercise Guide", "Kategorie treningowe, grupy mięśniowe i ekrany ćwiczeń z GIF oraz instrukcją techniki.", "Gotowe jako prototyp"],
                ["Notes", "Proste notatki z lokalnym zapisem CRUD.", "Gotowe"],
            ],
            [3.0, 10.0, 3.0],
        ),
        p("2.1. Scenariusze użytkownika", "H2"),
        numbers(
            [
                "Użytkownik otwiera aplikację i z ekranu głównego przechodzi do dziennika treningów.",
                "Użytkownik zapisuje trening z datą, czasem trwania, fokusem, listą ćwiczeń i opcjonalnym zdjęciem.",
                "Użytkownik filtruje treningi według okresu oraz sortuje je według daty.",
                "Użytkownik przegląda przepisy, zawęża listę po kategorii, czasie i trudności, a wybrany przepis dodaje do dziennika posiłków.",
                "Użytkownik otwiera przewodnik ćwiczeń, wybiera partię mięśniową i ogląda animację techniki.",
                "Użytkownik zapisuje krótką notatkę, później ją edytuje albo usuwa.",
            ]
        ),
    ]

    story += [
        p("3. Technologie, zależności i konfiguracja", "H1"),
        p("Projekt wykorzystuje Flutter jako framework UI oraz Dart jako język implementacji. Aplikacja jest budowana w stylu Material 3, z naciskiem na karty, przyciski, chipy, panele formularzy i prostą nawigację ekranową. Konfiguracja pubspec.yaml wskazuje wersję projektu 1.0.0+1 oraz środowisko Dart SDK ^3.8.1."),
        table(
            ["Technologia / pakiet", "Rola w projekcie"],
            [
                ["Flutter / Dart", "Warstwa aplikacji mobilnej, UI, logika ekranów i modele danych."],
                ["Material 3", "Spójny system wizualny, komponenty interfejsu i paleta kolorów."],
                ["sqflite", "Lokalne bazy SQLite dla treningów, notatek, posiłków i ulubionych przepisów."],
                ["path", "Budowanie ścieżek do baz i plików zdjęć."],
                ["transparent_image", "Ładowanie obrazów z łagodnym placeholderem."],
                ["image_picker", "Wybór zdjęć treningu z urządzenia."],
                ["intl", "Formatowanie dat w UI."],
                ["flutter_test", "Testy jednostkowe i widgetowe."],
                ["sqflite_common_ffi", "Testowanie baz SQLite w środowisku desktop/CI."],
            ],
            [4.5, 11.5],
        ),
        p("Aplikacja ma skonfigurowane zasoby w pubspec.yaml: zdjęcia ogólne, zdjęcia posiłków, pliki JSON oraz foldery z GIF-ami dla ćwiczeń. Dzięki temu katalog przepisów i przewodnik ćwiczeń działają bez pobierania mediów z internetu podczas używania aplikacji."),
    ]

    story += [
        p("4. Architektura projektu", "H1"),
        p("Architektura jest modułowa i typowa dla średniej wielkości aplikacji Flutter. Punkt wejścia znajduje się w pliku lib/main.dart, gdzie uruchamiany jest MyApp. Aplikacja korzysta z MaterialApp, wyłącza debug banner, ustawia tytuł Fit Diary, podłącza globalny motyw AppTheme.light i jako ekran startowy wskazuje StartScreen."),
        Image(str(diagram), width=16.4 * cm, height=9.4 * cm),
        p("Rysunek 1. Uproszczona architektura logiczna aplikacji.", "Caption"),
        p("4.1. Struktura katalogów", "H2"),
        table(
            ["Katalog", "Znaczenie"],
            [
                ["lib/start", "Ekran główny, karty szybkich akcji i modele kategorii startowych."],
                ["lib/trainings", "Dziennik treningów: model, baza danych, formularze i UI listy."],
                ["lib/train_help", "Przewodnik ćwiczeń: modele, dane kategorii, usługa ładowania JSON i ekrany."],
                ["lib/meals", "Moduł żywienia: kategorie, przepisy, meal log, baza SQLite i widgety obrazów."],
                ["lib/notes", "Prosty moduł notatek z osobną bazą SQLite."],
                ["assets/data", "Katalogi JSON: kategorie przepisów, przepisy, ćwiczenia."],
                ["assets/images", "Zdjęcia startowe, zdjęcia posiłków i media treningowe."],
                ["test", "Testy modeli, baz danych, katalogów zasobów i przepływów widgetowych."],
            ],
            [4.2, 11.8],
        ),
        p("4.2. Przepływ danych", "H2"),
        p("W aplikacji występują dwa główne typy danych: dane katalogowe i dane użytkownika. Dane katalogowe są wczytywane z JSON oraz assets i obejmują przepisy, kategorie przepisów oraz ćwiczenia. Dane użytkownika są zapisywane w SQLite: treningi w training_reports.db, wpisy posiłków i ulubione przepisy w meal_log.db, a notatki w tasks.db."),
        bullets(
            [
                "Ekrany stanowe pobierają dane w initState lub po powrocie z formularza.",
                "Formularze zwracają dane do ekranu nadrzędnego, który zapisuje je przez serwis bazy danych.",
                "Po zapisie ekran odświeża stan i pokazuje aktualną listę lub statystyki.",
                "Dane katalogowe są niemutowalne z perspektywy użytkownika i są ładowane z plików aplikacji.",
            ]
        ),
    ]

    story += [
        p("5. Moduły aplikacji", "H1"),
        p("5.1. Ekran startowy", "H2"),
        p("StartScreen pełni funkcję centrum aplikacji. Pokazuje aktualną datę, krótki opis aplikacji, kartę ostatniego treningu oraz siatkę szybkich akcji. Po przejściu do innego modułu i powrocie ekran ponownie ładuje ostatni trening, dzięki czemu karta główna pozostaje aktualna."),
        p("Ważną decyzją projektową było usunięcie nadmiarowego bloku Explore training z dołu ekranu głównego. Dzięki temu ekran jest czystszy, mieści się bez niepotrzebnego przewijania i nie przeciąża użytkownika powtórzeniem tych samych akcji."),
        p("5.2. Workout Log", "H2"),
        p("Workout Log jest najważniejszym modułem produktowym. Użytkownik może zapisać trening wraz z datą, czasem trwania jako liczbą minut, fokusem treningu, listą ćwiczeń oraz opcjonalnym zdjęciem. Moduł obsługuje także edycję istniejących wpisów, usuwanie raportów oraz automatyczne usuwanie powiązanego pliku zdjęcia."),
        table(
            ["Element", "Implementacja"],
            [
                ["Model", "TrainingReport: id, date, imagePath, durationMinutes, focus, exercises."],
                ["Baza danych", "training_reports.db, tabela training_reports, wersja 2."],
                ["Migracja", "Dodanie durationMinutes i focus dla starszych wpisów."],
                ["Pliki zdjęć", "Kopiowanie do katalogu training_report_images przy bazie danych."],
                ["Statystyki", "Liczba treningów w tygodniu, ostatni trening, średni czas trwania."],
                ["UX", "Bottom sheet formularza, filtry, sortowanie, placeholder dla braku zdjęcia."],
            ],
            [4.0, 12.0],
        ),
        p("5.3. Nutrition i Recipes", "H2"),
        p("Moduł Nutrition składa się z dwóch zakładek: Meal Log oraz Recipes. Meal Log pozwala rejestrować wpisy żywieniowe z datą, typem, tytułem, opcjonalnymi kaloriami, opcjonalnym białkiem i notatkami. Zakładka Recipes działa jako katalog przepisów i umożliwia wyszukiwanie, filtrowanie oraz dodawanie przepisu bezpośrednio do dziennika posiłków."),
        p("W module zastosowano optymalizację renderowania: lista przepisów korzysta z CustomScrollView i SliverList.builder, dzięki czemu karty przepisów są budowane leniwie. Widget MealImage obsługuje ograniczenie rozmiaru dekodowania obrazu przez cacheWidth i cacheHeight, co zmniejsza ryzyko przycięć klatek na telefonie."),
        table(
            ["Cecha", "Opis"],
            [
                ["Katalog", f"{len(meals)} przepisów w assets/data/meals.json."],
                ["Kategorie", f"{len(categories)} kategorii przepisów w assets/data/categories.json."],
                ["Filtry", "Kategoria, czas przygotowania, trudność, tylko ulubione."],
                ["Ulubione", "Tabela favorite_recipes w meal_log.db."],
                ["Meal Log", "Tabela meal_entries z kaloriami, białkiem i notatką."],
                ["Media", f"{meal_images} lokalnych zdjęć posiłków."],
            ],
            [4.0, 12.0],
        ),
        p("5.4. Exercise Guide", "H2"),
        p("Exercise Guide jest modułem edukacyjnym. Najpierw użytkownik wybiera duży obszar treningowy: Upper Body, Core lub Lower Body. Następnie przechodzi do grup mięśniowych, takich jak Arms, Back, Abs i Legs, a dalej do listy ćwiczeń. Ekran szczegółów zawiera nazwę ćwiczenia, animację GIF, opis oraz kroki techniczne."),
        table(
            ["Grupa mięśniowa", "Liczba ćwiczeń"],
            [[k, v] for k, v in sorted(exercise_by_muscle.items())],
            [8.0, 8.0],
        ),
        p("5.5. Notes", "H2"),
        p("Moduł Notes jest prostym, ale kompletnym przykładem lokalnego CRUD. Użytkownik może dodać notatkę, otworzyć ją do edycji, zmienić tytuł lub treść oraz usunąć wpis. Notatki są przechowywane w osobnej bazie tasks.db w tabeli tasks."),
    ]

    story += [
        p("6. Dane, baza SQLite i zasoby lokalne", "H1"),
        p("Projekt stosuje podejście offline-first. Dane użytkownika są zapisywane lokalnie, a treści katalogowe są dostarczane jako assets. To upraszcza demonstrację projektu, zmniejsza zależność od sieci oraz ułatwia testowanie."),
        p("6.1. Schemat baz danych", "H2"),
        table(
            ["Baza", "Tabela", "Najważniejsze pola", "Przeznaczenie"],
            [
                ["tasks.db", "tasks", "id, title, description", "Notatki użytkownika."],
                ["meal_log.db", "meal_entries", "id, date, type, title, calories, protein, notes", "Dziennik posiłków."],
                ["meal_log.db", "favorite_recipes", "mealId", "Ulubione przepisy."],
                ["training_reports.db", "training_reports", "id, date, imagePath, duration, durationMinutes, focus, exercises", "Raporty treningowe i migracja starszych danych."],
            ],
            [2.7, 3.2, 6.3, 3.8],
        ),
        p("6.2. Dane katalogowe", "H2"),
        table(
            ["Plik", "Liczba rekordów", "Rola"],
            [
                ["assets/data/categories.json", len(categories), "Kategorie przepisów."],
                ["assets/data/meals.json", len(meals), "Katalog przepisów z czasem, składnikami, krokami i flagami dietetycznymi."],
                ["assets/data/exercises.json", len(exercises), "Katalog ćwiczeń z opisem, GIF i krokami techniki."],
            ],
            [5.2, 3.1, 7.7],
        ),
        p("Rozkład przepisów wskazuje, że katalog jest nastawiony głównie na przepisy proste i niedrogie: "
          f"{complexity.get('simple', 0)} przepisów ma poziom simple, {complexity.get('challenging', 0)} challenging, "
          f"a {complexity.get('hard', 0)} hard. Pod względem affordability występuje {affordability.get('affordable', 0)} affordable, "
          f"{affordability.get('pricey', 0)} pricey i {affordability.get('luxurious', 0)} luxurious."),
        p("6.3. Zasoby multimedialne", "H2"),
        bullets(
            [
                f"{meal_images} zdjęć posiłków zapisanych lokalnie;",
                f"{training_gifs} GIF-ów treningowych w lokalnym przewodniku;",
                "własna ikona aplikacji w assets/branding oraz zasobach Android, iOS, macOS, web i Windows;",
                "plik assets/ATTRIBUTIONS.md z informacjami o źródłach i licencjach mediów.",
            ]
        ),
    ]

    story += [
        p("7. Interfejs użytkownika i doświadczenie użytkownika", "H1"),
        p("Interfejs został ujednolicony przez klasę AppTheme. Wykorzystuje Material 3, zielony seed color #1F7A5C, jasne tło #F7F9F5, białe karty, spójne zaokrąglenia, mocne nagłówki i konsekwentne style przycisków. Dzięki temu różne moduły nie wyglądają jak oddzielne eksperymenty, lecz jak części jednej aplikacji."),
        table(
            ["Decyzja UX", "Efekt dla użytkownika"],
            [
                ["Szybkie akcje na ekranie startowym", "Użytkownik od razu widzi najważniejsze obszary aplikacji."],
                ["Karta ostatniego treningu", "Aplikacja przypomina o realnej aktywności, a nie tylko pokazuje menu."],
                ["Bottom sheets dla formularzy", "Dodawanie danych nie wymaga pełnego przeładowania kontekstu."],
                ["Chipy i filtry", "Filtrowanie jest bardziej dotykowe i naturalne na telefonie."],
                ["Puste stany i placeholdery", "Brak danych nie wygląda jak błąd aplikacji."],
                ["Lokalne obrazy i GIF", "Treści są dostępne szybciej i bez zależności od internetu."],
            ],
            [5.4, 10.6],
        ),
        p("Dodatkową decyzją było utrzymanie aplikacji w języku angielskim. Jest to spójne z nazwą Fit Diary i może ułatwić prezentację projektu szerszej grupie odbiorców, ale w przyszłości warto rozważyć pełną lokalizację interfejsu."),
    ]

    story += [
        p("8. Testowanie i jakość", "H1"),
        p("Projekt posiada zestaw testów automatycznych obejmujących warstwę modeli, baz danych, katalogów zasobów oraz przepływów widgetowych. W dniu opracowania raportu uruchomiono flutter analyze oraz flutter test --reporter expanded --no-pub. Analizator nie zgłosił problemów, a wszystkie testy zakończyły się powodzeniem."),
        table(
            ["Sprawdzenie", "Wynik"],
            [
                ["flutter analyze", "No issues found"],
                ["flutter test --reporter expanded --no-pub", "24 testy zaliczone, 0 niezaliczonych"],
                ["Zakres testów", "Modele, bazy SQLite, migracje, integralność assets, scenariusze widgetowe."],
            ],
            [6.0, 10.0],
        ),
        p("8.1. Obszary pokrycia testami", "H2"),
        table(
            ["Plik testowy", "Co sprawdza"],
            [
                ["database_services_test.dart", "CRUD notatek, Meal Log, ulubione przepisy, treningi i migracje baz."],
                ["data_catalog_test.dart", "Poprawność katalogów JSON i istnienie lokalnych obrazów/GIF."],
                ["exercise_guide_widget_test.dart", "Przejście przez kategorie treningowe do szczegółów ćwiczenia."],
                ["nutrition_widget_test.dart", "Dodanie wpisu posiłku i aktualizacja podsumowania."],
                ["recipes_widget_test.dart", "Wyszukiwanie, filtry, ulubione i dodanie przepisu do Meal Log."],
                ["notes_widget_test.dart", "Dodanie, edycja i usunięcie notatki."],
                ["workout_log_widget_test.dart", "Dodanie treningu bez zdjęcia, edycja i usunięcie wpisu."],
                ["model tests", "Serializacja i zachowanie TrainingReport, MealEntry i Task."],
            ],
            [5.2, 10.8],
        ),
    ]

    story += [
        p("9. Wydajność, bezpieczeństwo i ograniczenia", "H1"),
        p("9.1. Wydajność", "H2"),
        p("Podczas testów na telefonie pojawiały się komunikaty Androida o pominiętych klatkach w trybie debug. W projekcie wykonano dwie istotne optymalizacje: listę przepisów przebudowano na leniwe slivery, a widget MealImage otrzymał cacheWidth i cacheHeight, aby ograniczyć dekodowanie obrazów większych niż potrzebne na ekranie. Dodatkowo najcięższe GIF-y treningowe zostały zmniejszone."),
        bullets(
            [
                "Recipes używa CustomScrollView i SliverList.builder zamiast budowania wszystkich kart jednocześnie.",
                "MealImage ogranicza rozmiar dekodowania obrazów na kartach i ekranach szczegółów.",
                "Duże GIF-y treningowe zostały zoptymalizowane do mniejszych rozmiarów, zachowując animację.",
                "Do ostatecznej oceny płynności zaleca się tryb flutter run --profile zamiast debug.",
            ]
        ),
        p("9.2. Prywatność i bezpieczeństwo", "H2"),
        p("Aplikacja nie wysyła danych użytkownika do zewnętrznego backendu. Treningi, posiłki i notatki są przechowywane lokalnie w SQLite. Jest to korzystne z punktu widzenia prywatności prototypu, ale jednocześnie oznacza brak synchronizacji między urządzeniami oraz brak kopii zapasowej."),
        p("9.3. Ograniczenia obecnej wersji", "H2"),
        bullets(
            [
                "brak backendu, kont użytkowników i synchronizacji;",
                "brak eksportu/importu danych użytkownika;",
                "brak zaawansowanych wykresów postępu treningowego;",
                "brak pełnej lokalizacji wielojęzycznej;",
                "brak podpisanej konfiguracji release i finalnego package id dla publikacji;",
                "część logiki UI znajduje się w dużych plikach ekranów, co w przyszłości warto podzielić na mniejsze komponenty;",
                "katalog ćwiczeń i przepisów jest statyczny, więc użytkownik nie może jeszcze dodawać własnych pozycji katalogowych.",
            ]
        ),
    ]

    story += [
        p("10. Plan dalszego rozwoju", "H1"),
        p("Najlepszym następnym krokiem jest potraktowanie projektu jako działającego prototypu i doprowadzenie go do wersji MVP. Oznacza to nie tyle dodawanie przypadkowych ekranów, ile dopracowanie najważniejszych funkcji, danych i jakości wydania."),
        table(
            ["Priorytet", "Zadanie", "Uzasadnienie"],
            [
                ["P1", "Dopracowanie Workout Log: wykresy, eksport danych, lepsze podsumowania.", "To główny moduł produktowy i najważniejsza wartość aplikacji."],
                ["P1", "Dopracowanie Nutrition: szczegóły przepisu, planowanie posiłków, własne przepisy.", "Nutrition jest drugim najważniejszym obszarem i ma potencjał codziennego użycia."],
                ["P2", "Backup/export lokalnej bazy.", "Bez tego użytkownik może stracić dane przy reinstalacji."],
                ["P2", "Lepsze statystyki i wykresy trendów.", "Zwiększa motywację i sprawia, że aplikacja wygląda bardziej produktowo."],
                ["P2", "Pełna lokalizacja PL/EN.", "Projekt można łatwiej prezentować w różnych kontekstach."],
                ["P3", "Backend i synchronizacja.", "Ważne dla produktu, ale niekonieczne dla pierwszego prototypu."],
                ["P3", "Publikacja release: ikona, podpis, package id, polityka prywatności.", "Wymagane przed realnym wydaniem w sklepie."],
            ],
            [2.0, 7.2, 6.8],
        ),
        p("10.1. Proponowany MVP", "H2"),
        numbers(
            [
                "Stabilizacja obecnych funkcji i ręczne testy na fizycznym telefonie w trybie profile.",
                "Eksport danych treningów i posiłków do pliku lokalnego.",
                "Wykres tygodniowej aktywności i średniego czasu treningu.",
                "Ekran szczegółów przepisu z czytelniejszym układem składników i kroków.",
                "Przegląd accessibility: kontrast, rozmiary dotykowe, opisy obrazów.",
                "Przygotowanie release Android: applicationId, signing config, wersjonowanie i finalna nazwa.",
            ]
        ),
    ]

    story += [
        p("11. Instrukcja uruchomienia", "H1"),
        p("Projekt można uruchomić lokalnie standardowymi komendami Flutter. Dla testowania na telefonie wymagane jest włączenie opcji programistycznych, USB debugging oraz autoryzacja urządzenia w ADB. Na urządzeniach Xiaomi/Redmi/POCO może być dodatkowo potrzebne włączenie instalacji przez USB."),
        table(
            ["Cel", "Komenda"],
            [
                ["Pobranie zależności", "flutter pub get"],
                ["Uruchomienie aplikacji", "flutter run"],
                ["Uruchomienie na konkretnym telefonie", "flutter run -d 9f1145f4"],
                ["Tryb wydajnościowy", "flutter run --profile -d 9f1145f4"],
                ["Analiza statyczna", "flutter analyze"],
                ["Testy", "flutter test"],
                ["Debug APK", "flutter build apk --debug"],
            ],
            [6.0, 10.0],
        ),
        p("12. Wnioski końcowe", "H1"),
        p("Fit Diary jest projektem o wyraźnej wartości użytkowej: łączy dziennik treningowy, przewodnik ćwiczeń, notatki i żywienie w jednym lekkim narzędziu. Najmocniejsze strony projektu to lokalna persistencja danych, spójny interfejs, realne zasoby multimedialne oraz testy automatyczne potwierdzające najważniejsze ścieżki działania."),
        p("Najważniejszym obszarem dalszej pracy jest przejście z prototypu do wersji MVP. Wymaga to przede wszystkim dopracowania eksportu danych, wykresów, szczegółów przepisów, release build oraz ręcznej walidacji na urządzeniu. Nie są to jednak fundamentalne braki architektoniczne, lecz naturalne kroki rozwojowe po zbudowaniu stabilnego prototypu."),
        callout(
            "Ocena końcowa",
            "Projekt można uznać za działający i dobrze rokujący prototyp aplikacji mobilnej. Ma logiczną strukturę, jasny zakres funkcji, lokalne dane, testy oraz spójny branding. Wymaga jeszcze opakowania produkcyjnego, ale jako projekt uczelniany lub demonstracyjny jest kompletny i przekonujący.",
        ),
    ]

    story += [
        p("Załącznik A. Metryki projektu", "H1"),
        table(
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
            [8.0, 8.0],
        ),
        p("Załącznik B. Rozkład katalogu przepisów", "H1"),
        table(
            ["Wymiar", "Rozkład"],
            [
                ["Trudność", ", ".join(f"{k}: {v}" for k, v in complexity.items())],
                ["Koszt", ", ".join(f"{k}: {v}" for k, v in affordability.items())],
                ["Kategorie", ", ".join(f"{k}: {v}" for k, v in sorted(meal_by_cat.items()))],
            ],
            [4.0, 12.0],
        ),
        p("Załącznik C. Źródła informacji w projekcie", "H1"),
        bullets(
            [
                "README.md - opis funkcjonalności, struktury i statusu prototypu;",
                "pubspec.yaml - zależności, wersja projektu i konfiguracja assets;",
                "lib/ - implementacja aplikacji Flutter;",
                "assets/data/*.json - katalog przepisów, kategorii i ćwiczeń;",
                "assets/ATTRIBUTIONS.md - informacje o źródłach i licencjach mediów;",
                "test/*.dart - testy automatyczne i scenariusze widgetowe;",
                "wyniki lokalnych komend: flutter analyze oraz flutter test --reporter expanded --no-pub.",
            ]
        ),
    ]

    doc.build(story, onFirstPage=footer, onLaterPages=footer)


EXCLUDED_DIRS = {
    ".git",
    ".dart_tool",
    ".gradle",
    ".idea",
    "build",
    "reports",
    "__pycache__",
}
EXCLUDED_FILE_SUFFIXES = {
    ".apk",
    ".aab",
    ".iml",
    ".zip",
    ".pdf",
    ".tmp",
    ".log",
}


def should_exclude(path: Path) -> bool:
    rel = path.relative_to(ROOT)
    parts = set(rel.parts)
    if parts & EXCLUDED_DIRS:
        return True
    if path.name in {"local.properties", ".flutter-plugins-dependencies"}:
        return True
    if path.name in {".DS_Store", "Thumbs.db"}:
        return True
    if path.suffix.lower() in EXCLUDED_FILE_SUFFIXES:
        return True
    return False


def build_zip() -> None:
    if ZIP_PATH.exists():
        ZIP_PATH.unlink()
    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in ROOT.rglob("*"):
            if not path.is_file() or should_exclude(path):
                continue
            archive.write(path, Path("Fit_Diary") / path.relative_to(ROOT))


if __name__ == "__main__":
    build_pdf()
    build_zip()
    print(PDF_PATH)
    print(ZIP_PATH)
