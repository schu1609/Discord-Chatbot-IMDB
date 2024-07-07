using System;
using System.Collections.Generic;
using System.Text;

namespace Chatbot.ChatbotModules
{
    public interface IPrologStream
    {
        public void WriteToDiscord(string prologMessage);
        public void WriteToProlog(string chatbotMessage);
        public string ReadToDiscord();
        public string ReadToProlog();
    }
}
