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
package com.esri.builder.components
{

import flash.events.Event;

public class FieldPickerEvent extends Event
{
    public static const FIELD_SELECTED:String = "fieldSelected";

    private var _template:String;

    public function get template():String
    {
        return _template;
    }

    public function FieldPickerEvent(type:String, template:String)
    {
        super(type);
        this._template = template;
    }

    public override function clone():Event
    {
        return new FieldPickerEvent(type, template);
    }
}
}
