#include "EditionBranding.h"
#include "Resources.h"
#include "graphics/MemoryImage.h"
#include <memory>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace EditionBranding
{
namespace
{
std::unique_ptr<Sexy::MemoryImage> nameImage;
std::unique_ptr<Sexy::MemoryImage> splashImage;

void PrepareTextImage(std::unique_ptr<Sexy::MemoryImage>& image, const char* label)
{
#ifdef _WIN32
    if (image)
        return;

    // Original bitmap fonts contain only a subset of Chinese characters.
    // Rasterize the edition name once with a local system font; no font is bundled.
    constexpr int width = 160;
    constexpr int height = 24;
    HDC dc = CreateCompatibleDC(nullptr);
    if (!dc)
        return;
    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = width;
    info.bmiHeader.biHeight = -height;
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    info.bmiHeader.biCompression = BI_RGB;
    void* pixels = nullptr;
    HBITMAP bitmap = CreateDIBSection(dc, &info, DIB_RGB_COLORS, &pixels, nullptr, 0);
    HFONT font = CreateFontW(-17, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        ANTIALIASED_QUALITY, DEFAULT_PITCH, L"Microsoft YaHei");
    if (!bitmap || !font)
    {
        if (font) DeleteObject(font);
        if (bitmap) DeleteObject(bitmap);
        DeleteDC(dc);
        return;
    }
    const auto oldBitmap = SelectObject(dc, bitmap);
    const auto oldFont = SelectObject(dc, font);
    PatBlt(dc, 0, 0, width, height, BLACKNESS);
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, RGB(255, 255, 255));
    wchar_t text[64]{};
    const int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, label, -1, text, 64);
    SIZE textSize{};
    if (length > 1) GetTextExtentPoint32W(dc, text, length - 1, &textSize);
    const bool drawn = length > 1 && TextOutW(dc, 0, 0, text, length - 1);
    GdiFlush();
    if (drawn)
    {
        const int textWidth = std::min(width, static_cast<int>(textSize.cx) + 2);
        image = std::make_unique<Sexy::MemoryImage>();
        image->Create(textWidth, height);
        auto* destination = image->GetBits();
        const auto* source = static_cast<const uint32_t*>(pixels);
        for (int y = 0; y < height; ++y)
        for (int x = 0; x < textWidth; ++x)
        {
            const uint32_t alpha = source[y * width + x] & 0xff;
            destination[y * textWidth + x] = (alpha << 24) | 0x00fff2c2;
        }
        image->BitsChanged();
    }
    SelectObject(dc, oldFont);
    SelectObject(dc, oldBitmap);
    DeleteObject(font);
    DeleteObject(bitmap);
    DeleteDC(dc);
#endif
}
}

void DrawBadge(Sexy::Graphics* graphics, int x, int y, int width)
{
    if (!Sexy::FONT_BRIANNETOD16 || !Sexy::FONT_BRIANNETOD12)
        return;
    PrepareTextImage(nameImage, Name);
    Sexy::Graphics badge(*graphics);
    badge.SetColor(Sexy::Color(28, 43, 30, 225));
    badge.FillRect(x, y, width, 52);
    badge.SetColor(Sexy::Color(190, 161, 86));
    badge.DrawRect(x, y, width - 1, 51);
    badge.FillRect(x, y, 3, 52);
    if (nameImage)
    {
        badge.SetColorizeImages(false);
        badge.DrawImage(nameImage.get(), x + 13, y + 4);
    }
    else
    {
        badge.SetFont(Sexy::FONT_BRIANNETOD16);
        badge.SetColor(Sexy::Color(255, 242, 194));
        badge.DrawString("WANZI CUSTOM", x + 13, y + 22);
    }
    badge.SetFont(Sexy::FONT_BRIANNETOD12);
    badge.SetColor(Sexy::Color(208, 221, 199));
    badge.DrawString(std::string("v") + Version + "  /  " + BuildId, x + 13, y + 41);
}

void ReleaseImages()
{
    nameImage.reset();
    splashImage.reset();
}

void DrawSplash(Sexy::Graphics* graphics, int width, int height, int alpha)
{
    PrepareTextImage(splashImage, SplashName);
    Sexy::Graphics splash(*graphics);
    const int centerX = width / 2;
    const int centerY = height / 2;
    splash.SetColor(Sexy::Color(25, 43, 30, alpha));
    splash.FillRect(centerX - 220, centerY - 86, 440, 172);
    splash.SetColor(Sexy::Color(190, 161, 86, alpha));
    splash.DrawRect(centerX - 220, centerY - 86, 439, 171);
    splash.FillRect(centerX - 42, centerY - 61, 84, 3);
    if (splashImage)
    {
        splash.SetColorizeImages(true);
        splash.SetColor(Sexy::Color(255, 255, 255, alpha));
        const int textWidth = splashImage->mWidth * 3;
        splash.DrawImage(splashImage.get(), centerX - textWidth / 2, centerY - 27, textWidth, 72);
    }
    splash.SetColor(Sexy::Color(190, 161, 86, alpha));
    splash.FillRect(centerX - 90, centerY + 61, 180, 1);
}
}
