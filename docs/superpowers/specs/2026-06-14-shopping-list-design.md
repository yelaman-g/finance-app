# Список покупок (ТЗ §4, низкий приоритет) — design

Дата: 2026-06-14
Статус: согласован (общий scope «реализуй все пункты»)

## 1. Цель
Совместный семейный список покупок: члены семьи добавляют позиции, отмечают «куплено»,
удаляют. ТЗ: «Совместный список в реальном времени, отметка куплено».

## 2. Границы
**Входит:** backend-модуль `shopping` (миграция V19 `shopping_items`, CRUD + toggle «куплено»,
семейный scope), эндпоинты `/api/v1/shopping`, фронт-фича `shopping` (экран, маршрут, вход из «Ещё»), тесты.
**Не входит:** «реал-тайм» через WebSocket — аппроксимируем pull-to-refresh / повторным
запросом (документировано); несколько именованных списков (один общий список на семью);
личные списки покупок (только семейный — по ТЗ «совместный»).

## 3. Модель — миграция V19 `shopping_items`
```sql
CREATE TABLE shopping_items (
    id           UUID PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    title        VARCHAR(200) NOT NULL,
    checked      BOOLEAN NOT NULL DEFAULT FALSE,
    created_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    version      BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_shopping_items_household ON shopping_items (household_id);
```
Сущность `ShoppingItem extends BaseEntity` (пакет `com.aifb.platform.shopping.domain`).

## 4. Backend — модуль `shopping`
- `ShoppingItemRepository`: `findByHouseholdIdOrderByCheckedAscUpdatedAtDesc(UUID householdId)`.
- `ShoppingService` (семейный scope через `HouseholdContextService`):
  - `list(userId)` → `requireMembership` → позиции домохозяйства (если не в семье — пусто).
  - `add(userId, title)` → `requireContribute` (GUEST нельзя) → новая позиция (household, createdBy=userId).
  - `toggle(userId, id)` → `requireContribute` → позиция должна быть в household пользователя; инвертирует `checked`.
  - `delete(userId, id)` → `requireContribute` → удаление позиции своего household.
  - Чужой household / нет членства → `NotFoundException`/`ForbiddenException` (как в других сервисах).
- `ShoppingController` `/api/v1/shopping` (JWT): `GET` (список), `POST {title}` (добавить),
  `POST /{id}/toggle` (отметить/снять «куплено»), `DELETE /{id}`.
- DTO: `ShoppingItemResponse(UUID id, String title, boolean checked, UUID createdBy)`,
  `AddShoppingItemRequest(@NotBlank @Size(max=200) String title)`.
- `ApiResponse`-конверт, `@CurrentUser AuthPrincipal`.

## 5. Frontend — фича `shopping`
- `lib/features/shopping/`: data (dto plain-класс, datasource на `/shopping` через `dioProvider`,
  repository), providers (repo + `shoppingListProvider` FutureProvider.autoDispose), presentation
  (`ShoppingPage`).
- **Экран:** список позиций (CheckboxListTile: чек = куплено → `POST /{id}/toggle`, куплённые
  приглушены/зачёркнуты), поле ввода + кнопка «Добавить», удаление по свайпу/long-press.
  Pull-to-refresh (RefreshIndicator) перезапрашивает список (аппроксимация «реал-тайма»).
- Маршрут `/shopping` (top-level GoRoute) + пункт `InsetTile` «Список покупок» в «Ещё»
  (`more_page.dart`), иконка `Icons.shopping_cart_rounded`.
- Если пользователь не в семье — мягкое сообщение «Создайте/вступите в семью».

## 6. Тесты
- Backend `ShoppingApiIT`: добавить→список содержит; toggle меняет checked; delete убирает;
  семейный scope (член семьи B видит позицию, добавленную A); GUEST не может добавить (403);
  auth required (401).
- Frontend: repo-тест (datasource→DTO, add/toggle/delete) + виджет-тест `ShoppingPage`
  (рендер списка + чек) с мок-репозиторием.

## 7. Риски
- Не настоящий real-time (pull-to-refresh) — для MVP/демо достаточно; WebSocket — отдельная задача.
- Один общий список на семью (без категорий/нескольких списков) — осознанное упрощение.
