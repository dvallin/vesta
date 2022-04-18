import { Redirect, Route, Switch } from "react-router-dom";
import {
  IonApp,
  IonIcon,
  IonLabel,
  IonRouterOutlet,
  IonSpinner,
  IonTabBar,
  IonTabButton,
  IonTabs,
  setupIonicReact,
} from "@ionic/react";
import { IonReactRouter } from "@ionic/react-router";
import {
  createOutline,
  searchOutline,
  cartOutline,
  pizzaOutline,
} from "ionicons/icons";

import EditMealPlan from "./pages/meal-plan/edit";
import MealPlanView from "./pages/meal-plan/view";

import AddRecipe from "./pages/recipe/add";
import EditRecipe from "./pages/recipe/edit";
import RecipeSearch from "./pages/recipe/search";
import RecipeView from "./pages/recipe/view";

import ShoppingListView from "./pages/shopping-list/view/view";
import ShoppingListAddMealPlan from "./pages/shopping-list/add-meal-plan/add-meal-plan";
import EditShoppingList from "./pages/shopping-list/edit/edit";

/* Core CSS required for Ionic components to work properly */
import "@ionic/react/css/core.css";

/* Basic CSS for apps built with Ionic */
import "@ionic/react/css/normalize.css";
import "@ionic/react/css/structure.css";
import "@ionic/react/css/typography.css";

/* Optional CSS utils that can be commented out */
import "@ionic/react/css/padding.css";
import "@ionic/react/css/float-elements.css";
import "@ionic/react/css/text-alignment.css";
import "@ionic/react/css/text-transformation.css";
import "@ionic/react/css/flex-utils.css";
import "@ionic/react/css/display.css";

/* Theme variables */
import "./theme/variables.css";
import { Suspense } from "react";

setupIonicReact();

const App: React.FC = () => (
  <Suspense fallback={<IonSpinner />}>
    <IonApp>
      <IonReactRouter>
        <IonTabs>
          <IonRouterOutlet>
            <Switch>
              <Route exact path="/recipe/search">
                <RecipeSearch />
              </Route>
              <Route exact path="/recipe/add">
                <AddRecipe />
              </Route>
              <Route exact path="/recipe/:recipeId/edit">
                <EditRecipe />
              </Route>
              <Route exact path="/recipe/:recipeId">
                <RecipeView />
              </Route>

              <Route path="/meal-plan/edit">
                <EditMealPlan />
              </Route>
              <Route path="/meal-plan">
                <MealPlanView />
              </Route>

              <Route exact path="/shopping-list/edit">
                <EditShoppingList />
              </Route>
              <Route exact path="/shopping-list/add-meal-plan">
                <ShoppingListAddMealPlan />
              </Route>
              <Route exact path="/shopping-list">
                <ShoppingListView />
              </Route>

              <Route exact path="/">
                <Redirect to="/meal-plan" />
              </Route>
            </Switch>
          </IonRouterOutlet>
          <IonTabBar slot="bottom">
            <IonTabButton tab="recipe-search" href="/recipe/search">
              <IonIcon icon={searchOutline} />
              <IonLabel>Search</IonLabel>
            </IonTabButton>
            <IonTabButton tab="add-recipe" href="/recipe/add">
              <IonIcon icon={createOutline} />
              <IonLabel>Write</IonLabel>
            </IonTabButton>
            <IonTabButton tab="meal-plan" href="/meal-plan">
              <IonIcon icon={pizzaOutline} />
              <IonLabel>Plan</IonLabel>
            </IonTabButton>
            <IonTabButton tab="shopping-list" href="/shopping-list">
              <IonIcon icon={cartOutline} />
              <IonLabel>Shop</IonLabel>
            </IonTabButton>
          </IonTabBar>
        </IonTabs>
      </IonReactRouter>
    </IonApp>
  </Suspense>
);

export default App;
