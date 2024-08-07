﻿using Discord;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Text;

namespace Chatbot.ChatbotModules
{
    class PrologStream: IPrologStream
    {
        static BlockingCollection<string> messagesFromDiscordBot = new BlockingCollection<string>();
        static BlockingCollection<string> messagesFromProlog = new BlockingCollection<string>();
        public PrologStream() { }
        public string ReadToProlog()
        {
            return messagesFromDiscordBot.Take();
        }
        public string ReadToDiscord()
        {
            return messagesFromProlog.Take();
        }
        public void WriteToDiscord(string prologMessage)
        {
            messagesFromProlog.Add(prologMessage);
        }
        public void WriteToProlog(string chatbotMessage)
        {
            messagesFromDiscordBot.Add(chatbotMessage);
        }
    }
}
