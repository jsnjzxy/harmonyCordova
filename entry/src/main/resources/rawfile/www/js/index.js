/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

// Wait for the deviceready event before using any of Cordova's device APIs.
// See https://cordova.apache.org/docs/en/latest/cordova/events/events.html#deviceready


var app = {
    // Application Constructor
    initialize: function () {
        this.bindEvents();
    },
    bindEvents: function () {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    onDeviceReady: function () {
        app.receivedEvent('deviceready');
    },
    receivedEvent: function (id) {
        var parentElement = document.getElementById(id);
        var listeningElement = parentElement.querySelector('.listening');
        var receivedElement = parentElement.querySelector('.received');

        listeningElement.setAttribute('style', 'display:none;');
        receivedElement.setAttribute('style', 'display:block;');

        console.log('Received Event: ' + id);
    },
};

app.initialize();


let flag = 0;
let timer = null;

function execRunner(onSuccess, onFail, server, action, args = []) {
    if (!window.cordova || !window.cordova.exec) {
        timer = setInterval(() => {
            flag++;
            if (window.cordova && window.cordova.exec) {
                clearInterval(timer);
                execRunner(onSuccess, onFail, server, action, args = []);
            }
            if (flag > 2000) {
                clearInterval(timer);
                return;
            }
        }, 10);
        return Promise.reject('[Error] Cordova load error.');
    }

    if (!server || !action) {
        return Promise.reject('[Error] server & action is required.');
    }

    const exec = window.cordova.exec;
    return new Promise((resolve, reject) => {
        exec(res => {
            alert('result: ' + res);
            res = onSuccess ? onSuccess(res) : res;
            resolve(res);
        }, e => {
            e = onFail ? onFail(e) : e;
            reject(e);
        }, server, action, args);
    });
}

const getPhoneInfo = () => {
    execRunner(
        res => JSON.parse(res),
        null,
        'DeviceInfo',
        'phoneInfo'
    );
}

const getLocation = () => {
    return execRunner(res => res && JSON.parse(res), e => {
        try {
            return JSON.parse(e);
        }
        catch (e) {
            return e;
        }
    }, 'Location', 'getLocation');
};
