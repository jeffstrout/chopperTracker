# Chopper Tracker Icon Design Instructions for Canva

## Brand Overview
**App Name:** Chopper Tracker  
**Purpose:** Real-time helicopter and aircraft tracking web application  
**Primary Focus:** Helicopters (with secondary support for airplanes)  
**Brand Colors:** Match the existing app theme (provide screenshots of current UI)

## Required Icon Types and Sizes

### 1. App Icon / Logo
**Purpose:** Main brand identity, app stores, website header  
**Formats Needed:**
- Square version: 1024x1024px (master file)
- Square exports: 512x512px, 256x256px, 128x128px, 64x64px, 32x32px
- Rectangular version: 1200x630px (for social media sharing)
- SVG version for scalability

**Design Guidelines:**
- Feature a helicopter silhouette or rotor blade design
- Should work on both light and dark backgrounds
- Keep it simple and recognizable at small sizes
- Consider incorporating location/radar elements

### 2. Favicon Set
**Purpose:** Browser tabs and bookmarks  
**Sizes Required:**
- 16x16px (ICO format)
- 32x32px (ICO format)
- 48x48px (PNG)
- 64x64px (PNG)
- 180x180px (PNG - Apple Touch Icon)
- 192x192px (PNG - Android Chrome)
- 512x512px (PNG - PWA)

**Design Notes:**
- Must be extremely simple due to tiny size
- Consider just helicopter rotor blades or "CT" monogram
- High contrast for visibility

### 3. Progressive Web App (PWA) Icons
**Purpose:** Mobile app installation, splash screens  
**Required Sizes:**
- 72x72px
- 96x96px
- 128x128px
- 144x144px
- 152x152px
- 192x192px
- 384x384px
- 512x512px

**Additional PWA Assets:**
- Splash screen: 2048x2732px (iPad Pro portrait)
- Splash screen: 1668x2388px (iPad portrait)
- Splash screen: 1242x2688px (iPhone portrait)
- Maskable icon: 512x512px with safe zone

### 4. Social Media Icons
**Purpose:** Social media profiles and sharing  
**Platforms & Sizes:**
- Facebook Profile: 170x170px (displays as circle)
- Facebook Cover: 820x312px
- Twitter/X Profile: 400x400px
- Twitter/X Header: 1500x500px
- LinkedIn Company: 300x300px
- LinkedIn Cover: 1128x191px
- Instagram Profile: 110x110px (displays as circle)
- YouTube Channel: 800x800px
- YouTube Banner: 2560x1440px

### 5. UI Icons (In-App Icons)
**Purpose:** Interface elements within the application  
**Size:** 24x24px base size (with 2x and 3x exports)  
**Required Icons:**
- Helicopter icon (top view with rotating blades)
- Airplane icon (top view)
- Location pin
- Filter/funnel icon
- Refresh/sync icon
- Settings gear
- Search magnifying glass
- Close/X button
- Menu hamburger
- Expand/collapse arrows
- Map layers icon
- Fit-to-view icon
- Online/offline status indicators
- Alert/warning triangle

**Export Requirements:**
- SVG format (preferred for scalability)
- PNG at 1x, 2x, 3x (24px, 48px, 72px)
- Consistent stroke width (2px at base size)
- Monochrome with transparency

### 6. Loading/Animation Assets
**Purpose:** Loading states and animations  
**Specifications:**
- Helicopter rotor spinner: 128x128px
- Animated GIF or sprite sheet
- 12-24 frames for smooth rotation
- Transparent background

### 7. Map Markers
**Purpose:** Aircraft positions on the map  
**Sizes:** 32x32px, 48x48px, 64x64px  
**Variants Needed:**
- Helicopter marker (active)
- Helicopter marker (inactive/old data)
- Helicopter marker (selected)
- Airplane marker (active)
- Airplane marker (inactive/old data)
- Airplane marker (selected)

**Design Requirements:**
- Clear directional indicator (nose/heading)
- High contrast for map visibility
- Shadow or outline for visibility on varied backgrounds

### 8. Error State Illustrations
**Purpose:** User-friendly error messages  
**Size:** 256x256px or 512x512px  
**Scenarios:**
- No aircraft in area
- Connection lost
- Loading error
- Rate limit exceeded
- No data available

## Design Specifications

### Color Requirements
- **Primary Colors:** Use existing app theme colors
- **Icon Colors:** Should work in monochrome
- **Accessibility:** Ensure WCAG AA contrast ratios

### Style Guidelines
- **Design Style:** Modern, clean, minimalistic
- **Line Weight:** Consistent across all icons
- **Corners:** Slightly rounded for friendliness
- **Shadows:** Subtle or none (flat design)

### File Naming Convention
```
choppertracker-[type]-[size].format
Examples:
- choppertracker-logo-512x512.png
- choppertracker-favicon-32x32.ico
- choppertracker-icon-helicopter-24x24.svg
- choppertracker-marker-helicopter-active-48x48.png
```

### Delivery Format
Please organize files in folders:
```
Chopper-Tracker-Icons/
├── App-Icons/
│   ├── Square/
│   ├── Rectangular/
│   └── SVG/
├── Favicons/
├── PWA-Icons/
├── Social-Media/
│   ├── Facebook/
│   ├── Twitter/
│   └── [etc...]
├── UI-Icons/
│   ├── SVG/
│   ├── PNG-1x/
│   ├── PNG-2x/
│   └── PNG-3x/
├── Map-Markers/
├── Loading-Assets/
└── Error-Illustrations/
```

## Additional Notes

### Inspiration Sources
- Aviation industry symbols
- Radar/tracking interfaces
- Military helicopter insignia
- Air traffic control displays
- GPS/navigation apps

### Key Visual Elements to Consider
- Helicopter rotor blades (cross/X pattern)
- Radar sweep lines
- Location/GPS indicators
- Flight path trails
- Altitude indicators
- Speed motion lines

### Export Settings
- **PNG:** Transparent background, optimized for web
- **SVG:** Cleaned paths, no unnecessary groups
- **ICO:** Multi-resolution (16x16, 32x32, 48x48 in one file)
- **Color Space:** sRGB
- **Optimization:** Compress all files for web delivery

## Testing Requirements
Icons should be tested for:
1. Visibility at smallest sizes
2. Recognition without color (grayscale test)
3. Clarity on both dark and light backgrounds
4. Loading performance (file size optimization)

## Questions for Designer
Before starting, please confirm:
1. Current brand colors (or should we establish new ones?)
2. Any existing brand guidelines to follow?
3. Preference for realistic vs. stylized helicopter representation?
4. Need for animated versions beyond loading spinner?