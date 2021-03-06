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
package com.esri.builder.controllers.supportClasses
{

import com.esri.builder.model.ViewerApp;

import flash.filesystem.File;

public class AppCreator
{
    private var appVersionReader:AppVersionReader;
    private var baseURL:String;

    public function AppCreator(appVersionReader:AppVersionReader, baseURL:String)
    {
        this.appVersionReader = appVersionReader;
        this.baseURL = baseURL;
    }

    public function createViewerFromDirectory(appDirectory:File):ViewerApp
    {
        const versionNumber:Number = appVersionReader.readVersionNumber(appDirectory);

        return isNaN(versionNumber) ? null : new ViewerApp(versionNumber,
                                                           appDirectory,
                                                           baseURL);
    }
}
}
