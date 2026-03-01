# Orbitalyte Levels - Template System

## Estructura

`LevelTemplate.tscn` contiene todos los elementos comunes a cualquier nivel:
- **Parallax2D** - Fondo con capas parallax
- **GameContainer** - Contenedor principal del juego
  - **PlanetsContainer** - Contiene StartPlanet, GoalPlanet y BlockerPlanets
  - **ShipVisuals** - Nave, trail y preview de lanzamiento
- **UIPanel** - Botones de control y barra de energía
- **GameManager** - Gestor del juego
- **InputManager** - Gestor de entrada

## Crear un Nuevo Nivel

### Opción 1: Duplicar y Modificar (Más rápido para comenzar)
1. Duplica `Level1.tscn` y renómbralo `Level3.tscn`
2. Abre `Level3.tscn`
3. En el editor, selecciona `GameContainer/PlanetsContainer`
4. Elimina los `BlockerPlanet` existentes
5. Agrega nuevos `BlockerPlanet.tscn` con las posiciones y configuraciones deseadas
6. Ajusta `GoalPlanet` y `StartPlanet` si lo necesitas

### Opción 2: Crear desde Cero (Más limpio)
1. Crea una nueva escena `Level3.tscn`
2. En el root, instancia `LevelTemplate.tscn`
3. Expande `Main > GameContainer > PlanetsContainer`
4. Agrega instancias de `BlockerPlanet.tscn` con tus configuraciones

## Elementos Personalizables por Nivel

En `GameContainer/PlanetsContainer` puedes:
- **Modificar BlockerPlanets**: posición, radio, gravedad, sprite, color
- **Modificar StartPlanet**: posición, sprite
- **Modificar GoalPlanet**: posición, sprite

Todo lo demás es común a todos los niveles.

## Script de Configuración

Los niveles se cargan automáticamente desde el `LevelManager`:
- Level 1: `res://MainScenes/Level1.tscn`
- Level 2: `res://MainScenes/Level2.tscn`
- Level 3: `res://MainScenes/Level3.tscn`

Cuando termines un nivel, el juego automáticamente carga el siguiente.
