PDF_FILE=$(ls -1r /mhlw_pdf/* | head -n 1)
echo "PDF_FILE|$PDF_FILE"
python3 /root/mhlw_pref_pdf_to_text.py $PDF_FILE
