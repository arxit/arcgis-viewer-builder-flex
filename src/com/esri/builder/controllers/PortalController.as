////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2008-2013 Esri. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////////////////////////////////////////////////////////////////////////////////
package com.esri.builder.controllers
{

import com.esri.ags.components.IdentityManager;
import com.esri.ags.components.supportClasses.Credential;
import com.esri.ags.events.IdentityManagerEvent;
import com.esri.ags.events.PortalEvent;
import com.esri.ags.portal.Portal;
import com.esri.builder.eventbus.AppEvent;
import com.esri.builder.model.Model;
import com.esri.builder.model.PortalModel;
import com.esri.builder.supportClasses.LogUtil;
import com.esri.builder.supportClasses.URLUtil;

import mx.logging.ILogger;
import mx.logging.Log;
import mx.resources.ResourceManager;
import mx.rpc.Fault;
import mx.rpc.events.FaultEvent;

public class PortalController
{
    private static const LOG:ILogger = LogUtil.createLogger(PortalController);

    private var lastUsedCultureCode:String;

    private var portal:Portal = PortalModel.getInstance().portal;

    public function PortalController()
    {
        AppEvent.addListener(AppEvent.SETTINGS_SAVED, settingsChangeHandler);
    }

    private function settingsChangeHandler(event:AppEvent):void
    {
        //optimization: AGO uses OAuth, so we register the OAuth info upfront
        var portalModel:PortalModel = PortalModel.getInstance();
        var portalURL:String = portalModel.portalURL;
        var cultureCode:String = Model.instance.cultureCode;
        if (portalModel.isAGO(portalURL))
        {
            portalModel.registerOAuthPortal(portalURL, cultureCode);
        }

        loadPortal(portalURL, cultureCode);
    }

    private function loadPortal(url:String, cultureCode:String):void
    {
        LOG.info("Loading Portal");

        if (url)
        {
            var hasPortalURLChanged:Boolean = (portal.url != url);
            var hasCultureCodeChanged:Boolean = (lastUsedCultureCode != cultureCode);
            if (hasPortalURLChanged || hasCultureCodeChanged)
            {
                LOG.debug("Reloading Portal - URL: {0}, culture code: {1}", url, cultureCode);

                if (hasPortalURLChanged)
                {
                    portal.unload();
                }

                lastUsedCultureCode = cultureCode;
                portal.culture = cultureCode;
                portal.url = URLUtil.removeToken(url);

                IdentityManager.instance.removeEventListener(IdentityManagerEvent.SIGN_IN, identityManager_signInHandler);
                portal.addEventListener(PortalEvent.LOAD, portal_loadHandler);
                portal.addEventListener(FaultEvent.FAULT, portal_faultHandler);
                portal.load();
            }
        }
        else
        {
            unloadPortal();
            dispatchPortalStatusUpdate();
        }
    }

    private function identityManager_signInHandler(event:IdentityManagerEvent):void
    {
        if (PortalModel.getInstance().hasSameOrigin(event.credential.server)
            && !PortalModel.getInstance().portal.signedIn)
        {
            signIntoPortalInternally();
        }
    }

    private function signIntoPortalInternally():void
    {
        AppEvent.removeListener(AppEvent.PORTAL_SIGN_IN, portalSignInHandler);
        IdentityManager.instance.removeEventListener(IdentityManagerEvent.SIGN_IN, identityManager_signInHandler);
        portal.addEventListener(PortalEvent.LOAD, portal_loadHandler);
        portal.addEventListener(FaultEvent.FAULT, portal_faultHandler);
        portal.signIn();
    }

    private function portal_loadHandler(event:PortalEvent):void
    {
        LOG.debug("Portal load success");

        //do nothing, load successful
        portal.removeEventListener(PortalEvent.LOAD, portal_loadHandler);
        portal.removeEventListener(FaultEvent.FAULT, portal_faultHandler);

        dispatchPortalStatusUpdate();
    }

    private function portal_faultHandler(event:FaultEvent):void
    {
        LOG.debug("Portal load fault");

        portal.removeEventListener(PortalEvent.LOAD, portal_loadHandler);
        portal.removeEventListener(FaultEvent.FAULT, portal_faultHandler);

        var fault:Fault = event.fault;
        if (fault.faultCode == "403" && fault.faultString == "User not part of this account")
        {
            var credential:Credential = IdentityManager.instance.findCredential(portal.url);
            if (credential)
            {
                credential.destroy();
            }

            AppEvent.dispatch(
                AppEvent.SHOW_ERROR,
                ResourceManager.getInstance().getString("BuilderStrings", "notOrgMember"));
        }
        else
        {
            dispatchPortalStatusUpdate();
        }
    }

    private function unloadPortal():void
    {
        LOG.debug("Unloading Portal");

        portal.url = null;
        portal.unload();
    }

    private function dispatchPortalStatusUpdate():void
    {
        updatePortalHandlersBasedOnStatus();
        AppEvent.dispatch(AppEvent.PORTAL_STATUS_UPDATED);
    }

    private function updatePortalHandlersBasedOnStatus():void
    {
        if (portal.signedIn)
        {
            AppEvent.addListener(AppEvent.PORTAL_SIGN_OUT, portalSignOutHandler);
            AppEvent.removeListener(AppEvent.PORTAL_SIGN_IN, portalSignInHandler);
            IdentityManager.instance.removeEventListener(IdentityManagerEvent.SIGN_IN, identityManager_signInHandler);
        }
        else
        {
            AppEvent.addListener(AppEvent.PORTAL_SIGN_IN, portalSignInHandler);
            IdentityManager.instance.addEventListener(IdentityManagerEvent.SIGN_IN, identityManager_signInHandler);
            AppEvent.removeListener(AppEvent.PORTAL_SIGN_OUT, portalSignOutHandler);
        }
    }

    private function portalSignOutHandler(event:AppEvent):void
    {
        LOG.info("Portal sign out requested");

        AppEvent.removeListener(AppEvent.PORTAL_SIGN_OUT, portalSignOutHandler);
        IdentityManager.instance.removeEventListener(IdentityManagerEvent.SIGN_IN, identityManager_signInHandler);
        portal.addEventListener(PortalEvent.LOAD, portal_loadHandler);
        portal.addEventListener(FaultEvent.FAULT, portal_faultHandler);
        portal.signOut();
    }

    private function portalSignInHandler(event:AppEvent):void
    {
        LOG.info("Portal sign in requested");

        signIntoPortalInternally();
    }
}

}
